import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/design_system/credit_card_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';

/// Zenvest Swipeable Bank Card Deck
/// Thiết kế thẻ ngân hàng lơ lửng vuốt ngang mượt mà chuẩn trang chủ Finora.
/// Tích hợp:
/// 1. Card Carousel vuốt ngang tự nhiên với độ bật nảy BouncingScrollPhysics,
///    nền chuyển màu thương hiệu ngân hàng từ CreditCardPalette, vầng hào quang cực quang
///    _BankBloomPainter, lớp phản quang Specular Sheen và viền pha lê phản quang 1.1px.
/// 2. Hàng chỉ báo Indicator Dots thông minh cho phép chạm hoặc vuốt chuyển thẻ tức thì.
/// 3. Dãy phím tác vụ nhanh (Quick Actions) riêng cho ví đang chọn: Xem lịch sử, Thêm thu chi, Sửa ví, Trả nợ thẻ.
/// 4. Danh sách giao dịch gần đây của ví đang chọn gọn gàng, thoáng đãng.
/// 5. Bảng chuyển đổi tài khoản nhanh (Compact Accounts Switcher) chạm là lật đến thẻ tương ứng.
class SwipeableBankCardDeck extends StatefulWidget {
  final List<Wallet> wallets;
  final List<TransactionModel> transactions;
  final String userId;
  final String? familyId;
  final bool isDark;
  final bool isMasked;
  final Function(Wallet wallet)? onHistory;
  final Function(Wallet wallet)? onEdit;
  final Function(Wallet wallet)? onDelete;
  final Function(Wallet wallet)? onPay;
  final Function(Wallet wallet)? onAddTransaction;
  final VoidCallback? onAddWallet;
  final int initialIndex;

  const SwipeableBankCardDeck({
    super.key,
    required this.wallets,
    required this.transactions,
    required this.userId,
    this.familyId,
    required this.isDark,
    required this.isMasked,
    this.onHistory,
    this.onEdit,
    this.onDelete,
    this.onPay,
    this.onAddTransaction,
    this.onAddWallet,
    this.initialIndex = 0,
  });

  @override
  State<SwipeableBankCardDeck> createState() => _SwipeableBankCardDeckState();
}

class _SwipeableBankCardDeckState extends State<SwipeableBankCardDeck> {
  late PageController _pageController;
  late int _activeIndex;
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialIndex.clamp(0, widget.wallets.isNotEmpty ? widget.wallets.length - 1 : 0);
    _pageController = PageController(
      initialPage: _activeIndex,
      viewportFraction: 0.95,
    );
  }

  @override
  void didUpdateWidget(covariant SwipeableBankCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeIndex >= widget.wallets.length && widget.wallets.isNotEmpty) {
      _activeIndex = widget.wallets.length - 1;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToWallet(int index) {
    if (index >= 0 && index < widget.wallets.length) {
      HapticFeedback.selectionClick();
      setState(() => _activeIndex = index);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  String _formatAmount(num val) {
    return _currencyFormat.format(val.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final wallets = widget.wallets;
    if (wallets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: widget.isDark ? 0.05 : 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có ví hoặc thẻ nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Thêm ví tiền mặt, ngân hàng hoặc thẻ tín dụng để bắt đầu theo dõi dòng tiền.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              if (widget.onAddWallet != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: widget.onAddWallet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Thêm ví mới', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0070F3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final activeWallet = wallets[_activeIndex.clamp(0, wallets.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header with title & Add Wallet button
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'DANH SÁCH VÍ & THẺ (${wallets.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: widget.isDark ? const Color(0xFFA3B4D4) : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${_activeIndex + 1}/${wallets.length}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onAddWallet != null) ...[
                const SizedBox(width: 8),
                FinoraAddButton(
                  onPressed: widget.onAddWallet!,
                  tooltip: 'Thêm ví mới',
                  size: 30,
                ),
              ],
            ],
          ),
        ),

        // 2. Swipeable Bank Card Deck Carousel (PageView)
        SizedBox(
          height: 212,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              controller: _pageController,
              physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: wallets.length,
              onPageChanged: (idx) {
                HapticFeedback.selectionClick();
                setState(() => _activeIndex = idx);
              },
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                return _buildSwipeableGlassCard(
                  wallet: wallet,
                  isSelected: index == _activeIndex,
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 4. Quick Action Dock for the Active Wallet
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _buildActiveWalletActions(activeWallet),
        ),

        const SizedBox(height: 16),

        // 5. Recent Transactions for the Active Wallet
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _buildWalletRecentTransactions(activeWallet),
        ),

        const SizedBox(height: 16),

        // 6. Compact All Accounts Switcher
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _buildCompactAccountsSwitcher(wallets, activeWallet),
        ),

        // Bottom space so content is not obscured by the floating dock
        const SizedBox(height: 90),
      ],
    );
  }

  // --- SWIPEABLE GLASS BANK CARD BUILDER ---

  Widget _buildSwipeableGlassCard({
    required Wallet wallet,
    required bool isSelected,
  }) {
    final brand = BankIconRegistry.resolve(wallet.bankCode, bankName: wallet.bankName ?? wallet.name);
    final isCash = brand.code == 'cash' ||
        wallet.type == 'cash' ||
        wallet.name.toLowerCase().contains('tiền mặt') ||
        wallet.name.toLowerCase().contains('cash');
    final isCredit = wallet.isCreditCard;
    final isBankBrand = !isCash && brand.code != 'cash';

    // Resolved colors from CreditCardPalette (tương tự như trang chủ, không pha trắng)
    final List<Color> cardColors;
    final Color brandColor;

    if (isCash) {
      cardColors = const [Color(0xFF06281D), Color(0xFF093527), Color(0xFF041A13)];
      brandColor = const Color(0xFF10B981);
    } else {
      final walletName = wallet.name.toLowerCase();
      var skin = wallet.themeColor ?? '';
      if (skin.isEmpty) {
        if (RegExp(r'gold|vàng').hasMatch(walletName)) {
          skin = 'gold';
        } else if (RegExp(r'silver|sliver|bạc|platinum').hasMatch(walletName)) {
          skin = 'silver';
        } else if (['mbbank', 'mb', 'bidv', 'acb', 'vtb', 'vietinbank', 'scb'].contains(brand.code)) {
          skin = 'blue';
        } else if (['vcb', 'vietcombank', 'vpb', 'vpbank', 'ocb'].contains(brand.code)) {
          skin = 'emerald';
        } else if (['tcb', 'techcombank', 'cake', 'hdb', 'hdbank', 'agri', 'agribank'].contains(brand.code)) {
          skin = 'rose';
        } else if (['tpb', 'tpbank', 'timo'].contains(brand.code)) {
          skin = 'purple';
        } else if (['shb', 'sea', 'seabank'].contains(brand.code)) {
          skin = 'orange';
        } else if (['vib', 'zalo', 'zalopay'].contains(brand.code)) {
          skin = 'cyan';
        } else if (['momo'].contains(brand.code)) {
          skin = 'pink';
        }
      }

      final resolved = skin.isNotEmpty ? CreditCardPalette.skins[skin.toLowerCase()] : null;
      if (resolved != null) {
        cardColors = resolved;
        brandColor = resolved.length >= 2 ? resolved[1] : (brand.color);
      } else if (isBankBrand) {
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

    final String cardTierOrDate;
    if (isCredit) {
      cardTierOrDate = wallet.creditLimit >= 50000000 ? 'FINORA PLATINUM' : 'CREDIT CARD';
    } else if (wallet.type == 'bank') {
      cardTierOrDate = 'DEBIT CARD';
    } else if (isCash) {
      cardTierOrDate = 'TIỀN MẶT';
    } else {
      cardTierOrDate = 'FINORA PAY';
    }

    final num displayBalance = isCredit && wallet.creditLimit > 0
        ? (wallet.creditLimit - wallet.currentDebt)
        : wallet.balance;

    final String displayCurrency = (brand.code != 'cash' && !isCash)
        ? brand.name.toUpperCase()
        : (isCash ? 'TIỀN MẶT' : 'VND');

    final accountNumber = wallet.accountNumber;
    final displayAccount = accountNumber != null && accountNumber.isNotEmpty
        ? '•••• •••• •••• ${accountNumber.substring(accountNumber.length > 4 ? accountNumber.length - 4 : 0)}'
        : (isCash ? 'TIỀN MẶT' : 'CHƯA CÓ STK');

    final owner = wallet.ownerName.isNotEmpty
        ? wallet.ownerName
        : (wallet.owner == 'wife' ? 'Vợ' : 'Chồng');

    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.96,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: brandColor.withValues(alpha: widget.isDark ? 0.42 : 0.28),
              blurRadius: 24,
              offset: const Offset(0, 8),
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

              // Layer 2: Hoa văn hào quang thương hiệu ngân hàng
              Positioned.fill(
                child: CustomPaint(
                  painter: _WalletBankBloomPainter(brandColor: brandColor, isDark: widget.isDark),
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

              // Layer 4: Nội dung thẻ chuẩn Zenvest với chữ trắng sắc nét
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Hàng trên: Logo Ngân Hàng & Tên + Sóng Contactless + 3-Dots Menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Flag & Currency / Bank Logo Pill
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isBankBrand && brand.assetPath != null)
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          brand.assetPath!,
                                          width: 18,
                                          height: 18,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              brand.name.isNotEmpty ? brand.name[0] : 'B',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else if (isCash)
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF10B981),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.payments_rounded, color: Colors.white, size: 10),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF0070F3),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.credit_card_rounded, color: Colors.white, size: 10),
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        displayCurrency,
                                        style: const TextStyle(
                                          fontSize: 11.5,
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
                        ),
                        const SizedBox(width: 8),

                        // Contactless wave & 3-dots Menu
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 85),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  cardTierOrDate,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              Icons.contactless_rounded,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            // Popup Menu Button
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onSelected: (val) {
                                if (val == 'history') widget.onHistory?.call(wallet);
                                if (val == 'edit') widget.onEdit?.call(wallet);
                                if (val == 'pay' && isCredit) widget.onPay?.call(wallet);
                                if (val == 'delete') widget.onDelete?.call(wallet);
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'history',
                                  child: Row(
                                    children: [
                                      Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF0070F3)),
                                      SizedBox(width: 10),
                                      Text('Xem lịch sử giao dịch', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, size: 18, color: Color(0xFF10B981)),
                                      SizedBox(width: 10),
                                      Text('Chỉnh sửa thông tin ví', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                if (isCredit)
                                  const PopupMenuItem(
                                    value: 'pay',
                                    child: Row(
                                      children: [
                                        Icon(Icons.credit_card_rounded, size: 18, color: Color(0xFFE11D48)),
                                        SizedBox(width: 10),
                                        Text('Thanh toán dư nợ thẻ', style: TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                      SizedBox(width: 10),
                                      Text('Xóa ví này', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Hàng giữa: Tên ví & Số dư lớn
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.isMasked ? '•••••••• ₫' : '₫ ${_formatAmount(displayBalance)}',
                            style: const TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        if (isCredit) ...[
                          const SizedBox(height: 4),
                          Builder(
                            builder: (_) {
                              final limit = wallet.creditLimit;
                              final spent = wallet.currentDebt;
                              final remaining = (limit - spent).clamp(0, limit);
                              final ratio = limit > 0
                                  ? (spent / limit).clamp(0.0, 1.0)
                                  : 0.0;
                              final isHighUsage = ratio > 0.85;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Đã tiêu: ${widget.isMasked ? '••••••' : formatVND(spent)}',
                                        style: TextStyle(
                                          fontSize: 9.8,
                                          fontWeight: FontWeight.w700,
                                          color: isHighUsage
                                              ? const Color(0xFFFECDD3)
                                              : Colors.white
                                                  .withValues(alpha: 0.88),
                                        ),
                                      ),
                                      Text(
                                        'Còn lại: ${widget.isMasked ? '••••••' : formatVND(remaining)}',
                                        style: TextStyle(
                                          fontSize: 9.8,
                                          fontWeight: FontWeight.w800,
                                          color: isHighUsage
                                              ? const Color(0xFFFCA5A5)
                                              : const Color(0xFF6EE7B7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3.5),
                                  Stack(
                                    children: [
                                      Container(
                                        height: 5.0,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.22),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor:
                                            ratio == 0.0 ? 0.02 : ratio,
                                        child: Container(
                                          height: 5.0,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            gradient: LinearGradient(
                                              colors: isHighUsage
                                                  ? const [
                                                      Color(0xFFF43F5E),
                                                      Color(0xFFE11D48),
                                                    ]
                                                  : const [
                                                      Color(0xFF38BDF8),
                                                      Color(0xFF10B981),
                                                    ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (isHighUsage
                                                        ? const Color(0xFFF43F5E)
                                                        : const Color(0xFF10B981))
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2.5),
                                  Text(
                                    'Hạn mức: ${formatVND(wallet.creditLimit)}',
                                    style: TextStyle(
                                      fontSize: 9.2,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.70),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),

                    // Hàng dưới: Số tài khoản + Chip vàng + Huy hiệu chủ sở hữu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Account number
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                displayAccount,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Owner Badge & Chip
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // EMV Chip simulation
                            Container(
                              width: 22,
                              height: 16,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 14,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF8B6508), width: 0.6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Owner Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 0.6),
                              ),
                              child: Text(
                                owner.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- QUICK ACTIONS BAR FOR ACTIVE WALLET ---

  Widget _buildActiveWalletActions(Wallet wallet) {
    final isCredit = wallet.isCreditCard;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (widget.isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: widget.isDark ? 0.65 : 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: widget.isDark ? 0.08 : 0.06),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.18 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildActionCapsule(
              icon: Icons.receipt_long_rounded,
              label: 'Lịch sử',
              color: const Color(0xFF0070F3),
              onTap: () => widget.onHistory?.call(wallet),
            ),
          ),
          Expanded(
            child: _buildActionCapsule(
              icon: Icons.add_circle_outline_rounded,
              label: 'Ghi thu chi',
              color: const Color(0xFF10B981),
              onTap: () => widget.onAddTransaction?.call(wallet),
            ),
          ),
          Expanded(
            child: _buildActionCapsule(
              icon: Icons.edit_note_rounded,
              label: 'Sửa ví',
              color: const Color(0xFFF59E0B),
              onTap: () => widget.onEdit?.call(wallet),
            ),
          ),
          if (isCredit)
            Expanded(
              child: _buildActionCapsule(
                icon: Icons.credit_card_rounded,
                label: 'Trả nợ',
                color: const Color(0xFFE11D48),
                onTap: () => widget.onPay?.call(wallet),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCapsule({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: widget.isDark ? 0.18 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RECENT TRANSACTIONS OF ACTIVE WALLET ---

  Widget _buildWalletRecentTransactions(Wallet wallet) {
    final recentTxs = widget.transactions
        .where((t) => t.walletId == wallet.id || t.toWalletId == wallet.id)
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (widget.isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: widget.isDark ? 0.55 : 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: widget.isDark ? 0.08 : 0.05),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'GIAO DỊCH GẦN ĐÂY CỦA VÍ',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? const Color(0xFFA3B4D4) : const Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (recentTxs.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => widget.onHistory?.call(wallet),
                  child: Text(
                    'Xem tất cả →',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF0F6E56),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (recentTxs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'Chưa có giao dịch gần đây trên ví này.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            Column(
              children: recentTxs.map((tx) {
                final isIncome = TransactionVisuals.isInflow(tx.type);
                final amountColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFE11D48);
                final prefix = isIncome ? '+' : '-';
                final dateStr = DateFormat('HH:mm · dd/MM').format(_parseDate(tx.date));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: (widget.isDark ? Colors.white : Colors.black)
                              .withValues(alpha: widget.isDark ? 0.08 : 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: CategoryIconWidget(
                            icon: tx.categoryIcon,
                            categoryName: tx.categoryName,
                            color: tx.categoryColor != null
                                ? BankIconRegistry.parseThemeColor(tx.categoryColor)
                                : amountColor,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (tx.note != null && tx.note!.isNotEmpty)
                                  ? tx.note!
                                  : (tx.categoryName != null && tx.categoryName!.isNotEmpty
                                      ? tx.categoryName!
                                      : 'Giao dịch'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 112),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            widget.isMasked ? '••••••' : '$prefix${formatVND(tx.amount)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: amountColor,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- COMPACT ACCOUNTS SWITCHER ---

  Widget _buildCompactAccountsSwitcher(List<Wallet> wallets, Wallet activeWallet) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (widget.isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: widget.isDark ? 0.55 : 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: widget.isDark ? 0.08 : 0.05),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'TẤT CẢ TÀI KHOẢN (${wallets.length})',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? const Color(0xFFA3B4D4) : const Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 92),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Chạm để lật thẻ',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: wallets.asMap().entries.map((entry) {
              final idx = entry.key;
              final w = entry.value;
              final isCurrent = w.id == activeWallet.id;
              final brand = BankIconRegistry.resolve(w.bankCode, bankName: w.bankName ?? w.name);
              final isCash = brand.code == 'cash' || w.type == 'cash';
              final displayBalance = w.isCreditCard && w.creditLimit > 0
                  ? (w.creditLimit - w.currentDebt)
                  : w.balance;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => _animateToWallet(idx),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? (const Color(0xFF0F6E56)).withValues(alpha: widget.isDark ? 0.18 : 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF0F6E56).withValues(alpha: 0.45)
                            : (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                        width: isCurrent ? 1.0 : 0.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Small Brand Avatar
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCash ? const Color(0xFF10B981) : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: isCash
                              ? const Center(child: Icon(Icons.payments_rounded, color: Colors.white, size: 14))
                              : (brand.assetPath != null
                                  ? ClipOval(
                                      child: Image.asset(
                                        brand.assetPath!,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            brand.name.isNotEmpty ? brand.name[0] : 'B',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Center(child: Icon(Icons.account_balance, size: 14, color: Colors.black))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                w.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                w.accountNumber != null && w.accountNumber!.isNotEmpty
                                    ? '•••• ${w.accountNumber!.substring(w.accountNumber!.length > 4 ? w.accountNumber!.length - 4 : 0)} · ${w.isCreditCard ? "Tín dụng" : "Thanh toán"}'
                                    : (isCash ? 'Ví tiền mặt' : 'Tài khoản'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                  widget.isMasked ? '••••••••' : formatVND(displayBalance),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isCurrent
                                        ? (widget.isDark ? const Color(0xFF34D399) : const Color(0xFF0F6E56))
                                        : (widget.isDark ? Colors.white70 : const Color(0xFF334155)),
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F6E56).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Đang xem',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: widget.isDark
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF0F6E56),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    if (raw is int) {
      if (raw <= 0) return DateTime.now();
      if (raw > 100000000000) return DateTime.fromMillisecondsSinceEpoch(raw);
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    if (raw is String) {
      final asInt = int.tryParse(raw);
      if (asInt != null) return _parseDate(asInt);
      try {
        return DateTime.parse(raw);
      } catch (_) {}
    }
    return DateTime.now();
  }
}

/// Aurora glowing bloom effect on bank cards
class _WalletBankBloomPainter extends CustomPainter {
  final Color brandColor;
  final bool isDark;

  const _WalletBankBloomPainter({
    required this.brandColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.50);

    // 1. Primary Bank Glow
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

    // 2. Luminous Tint Flare
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

    // 3. Soft Ambient Halo
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
  bool shouldRepaint(covariant _WalletBankBloomPainter oldDelegate) {
    return oldDelegate.brandColor != brandColor || oldDelegate.isDark != isDark;
  }
}
