import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/wallet.dart';
import '../../state/wallet_provider.dart';
import 'add_wallet_page.dart';
import '../transaction/add_transaction_page.dart';
import '../transaction/transaction_history_sheet.dart';

class WalletScreen extends StatefulWidget {
  final String userId;

  const WalletScreen({super.key, required this.userId});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _selectedOwner = 'all'; // 'all', 'husband', 'wife'
  bool _isCardView = true; // true = 3D Cards, false = List
  int _currentCardIndex = 0;

  String _maskedAccount(String? value) {
    final clean = (value ?? '').replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return '••••';
    final visible =
        clean.length <= 4 ? clean : clean.substring(clean.length - 4);
    return '•• $visible';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WalletProvider>().load(widget.userId);
    });
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _editWallet(Wallet wallet) =>
      _push(AddWalletPage(userId: widget.userId, wallet: wallet));

  void _payCreditCard(Wallet card) => _push(AddTransactionPage(
      userId: widget.userId,
      initialType: 'credit_card_payment',
      initialWalletId: card.id));

  void _showWalletHistory(Wallet wallet) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: .92,
        child: TransactionHistorySheet(
          userId: widget.userId,
          walletId: wallet.id,
          walletName: wallet.name,
        ),
      ),
    );
  }

  void _showWalletActions(Wallet wallet) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          if (wallet.isCreditCard)
            ListTile(
              leading: const Icon(Icons.payment_rounded),
              title: const Text('Thanh toán thẻ'),
              onTap: () {
                Navigator.pop(sheetContext);
                _payCreditCard(wallet);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Sửa tài khoản'),
            onTap: () {
              Navigator.pop(sheetContext);
              _editWallet(wallet);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Xóa tài khoản'),
            onTap: () {
              Navigator.pop(sheetContext);
              context
                  .read<WalletProvider>()
                  .deleteWallet(widget.userId, wallet.id);
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WalletProvider>();

    final allWallets = provider.wallets;
    final filtered = allWallets.where((w) {
      if (_selectedOwner == 'all') return true;
      return w.owner == _selectedOwner;
    }).toList();

    final creditCards = filtered.where((w) => w.isCreditCard).toList();
    final bankAccounts = filtered.where((w) => !w.isCreditCard).toList();

    final totalBalance = filtered.fold<double>(
        0, (sum, w) => sum + (!w.isCreditCard ? w.balance : 0));
    final totalDebt = filtered.fold<double>(
        0, (sum, w) => sum + (w.isCreditCard ? w.currentDebt : 0));
    final netWorth = totalBalance - totalDebt;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Ví tiền',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
          child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOwnerFilter(isDark),
              const SizedBox(height: 16),
              _buildHeroCard(
                  netWorth, totalBalance, totalDebt, filtered.length),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildViewToggleButton(
                            Icons.format_list_bulleted_rounded,
                            !_isCardView,
                            () => setState(() => _isCardView = false),
                            isDark),
                        const SizedBox(width: 4),
                        _buildViewToggleButton(
                            Icons.credit_card_rounded,
                            _isCardView,
                            () => setState(() => _isCardView = true),
                            isDark),
                      ],
                    ),
                  ),
                  FloatingActionButton.small(
                    onPressed: () =>
                        _push(AddWalletPage(userId: widget.userId)),
                    backgroundColor: const Color(0xFF0891B2),
                    elevation: 3,
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Thẻ tín dụng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${creditCards.length}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (creditCards.isEmpty)
                _buildEmptyPlaceholder('Chưa có thẻ tín dụng', isDark)
              else if (_isCardView)
                _buildCreditCardSwipeDeck(creditCards, isDark)
              else
                Column(
                  children: creditCards
                      .map((c) => _buildCreditCardListTile(c, isDark))
                      .toList(),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Ví tiền & Tài khoản ngân hàng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${bankAccounts.length}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (bankAccounts.isEmpty)
                _buildEmptyPlaceholder('Chưa có tài khoản ngân hàng', isDark)
              else
                Column(
                  children: bankAccounts
                      .map((w) => _buildBankAccountListTile(w, isDark))
                      .toList(),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildOwnerFilter(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
              child: _buildOwnerPill('Tất cả', _selectedOwner == 'all',
                  () => setState(() => _selectedOwner = 'all'), isDark)),
          Expanded(
              child: _buildOwnerPill('Chồng', _selectedOwner == 'husband',
                  () => setState(() => _selectedOwner = 'husband'), isDark)),
          Expanded(
              child: _buildOwnerPill('Vợ', _selectedOwner == 'wife',
                  () => setState(() => _selectedOwner = 'wife'), isDark)),
        ],
      ),
    );
  }

  Widget _buildOwnerPill(
      String text, bool active, VoidCallback onTap, bool isDark) {
    final activeColor = text == 'Chồng'
        ? const Color(0xFF2563EB)
        : text == 'Vợ'
            ? const Color(0xFFEC4899)
            : const Color(0xFF1E3A5F);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
      double netWorth, double totalBalance, double totalDebt, int count) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A3558),
            Color(0xFF0E7490),
            Color(0xFF2563A9),
            Color(0xFF38A3C7),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0891B2).withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG TÀI SẢN VÍ & THẺ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$count tài khoản',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(netWorth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tiền mặt khả dụng',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(totalBalance),
                      style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 14,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dư nợ thẻ tín dụng',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(totalDebt),
                      style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 14,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(
      IconData icon, bool active, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: active
              ? const Color(0xFF2563EB)
              : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _buildCreditCardSwipeDeck(List<Wallet> cards, bool isDark) {
    final card = cards[_currentCardIndex % cards.length];
    final brand =
        BankIconRegistry.resolve(card.bankCode ?? card.bankName ?? card.name);
    final baseColor = BankIconRegistry.parseThemeColor(card.themeColor,
        fallback: brand.color);
    final cardColors = [
      Color.lerp(baseColor, Colors.black, .35)!,
      baseColor,
      Color.lerp(baseColor, Colors.white, .16)!,
    ];
    final limit = card.creditLimit;
    final debt = card.currentDebt;
    final available = limit - debt;
    final usedRatio = limit > 0 ? (debt / limit).clamp(0.0, 1.0) : 0.0;
    final usedPercent = (usedRatio * 100).toStringAsFixed(1);

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showWalletHistory(card),
          onHorizontalDragEnd: (details) {
            if (cards.length < 2) return;
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 120) return;
            setState(() {
              if (velocity < 0) {
                _currentCardIndex = (_currentCardIndex + 1) % cards.length;
              } else {
                _currentCardIndex =
                    (_currentCardIndex - 1 + cards.length) % cards.length;
              }
            });
            HapticFeedback.selectionClick();
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: cardColors,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: BankIcon(
                              bankCode: card.bankCode ?? 'tcb', size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.name.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'THẺ TÍN DỤNG • ' +
                                  (card.owner == 'husband' ? 'Chồng' : 'Vợ'),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      onPressed: () => _showWalletActions(card),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 34, height: 34),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hạn mức:',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(Formatters.formatCurrency(limit),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Khả dụng:',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(Formatters.formatCurrency(available),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: usedRatio,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _payCreditCard(card),
                      icon: const Icon(Icons.payment_rounded,
                          size: 16, color: Color(0xFF047857)),
                      label: const Text('Thanh toán',
                          style: TextStyle(
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Đã dùng: ' + usedPercent + '%',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        Text(Formatters.formatCurrency(debt),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (cards.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cards.length, (i) {
              final active = i == (_currentCardIndex % cards.length);
              return GestureDetector(
                onTap: () => setState(() => _currentCardIndex = i),
                child: Container(
                  width: active ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF2563EB)
                        : (isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildCreditCardListTile(Wallet card, bool isDark) {
    final limit = card.creditLimit;
    final debt = card.currentDebt;
    final available = limit - debt;
    final usedRatio = limit > 0 ? (debt / limit).clamp(0.0, 1.0) : 0.0;
    final brand =
        BankIconRegistry.resolve(card.bankCode ?? card.bankName ?? card.name);
    final accent = BankIconRegistry.parseThemeColor(card.themeColor,
        fallback: brand.color);

    return GestureDetector(
      onTap: () => _showWalletHistory(card),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color:
              isDark ? const Color(0xFF1E293B) : accent.withValues(alpha: .045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : accent.withValues(alpha: .12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BankIcon(bankCode: card.bankCode ?? 'tcb', size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name.toUpperCase(),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6)),
                            child: const Text('TÍN DỤNG',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFEF4444))),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(
                                card.owner == 'husband' ? 'Chồng' : 'Vợ',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB))),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _maskedAccount(card.accountNumber),
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showWalletActions(card),
                  icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 36),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dư nợ',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text(Formatters.formatCurrency(debt),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEF4444))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Khả dụng',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text(Formatters.formatCurrency(available),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usedRatio,
                minHeight: 4,
                backgroundColor:
                    isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountListTile(Wallet wallet, bool isDark) {
    final brand = BankIconRegistry.resolve(
        wallet.bankCode ?? wallet.bankName ?? wallet.name);
    final accent = BankIconRegistry.parseThemeColor(wallet.themeColor,
        fallback: brand.color);
    return GestureDetector(
      onTap: () => _showWalletHistory(wallet),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: BankIcon(bankCode: wallet.bankCode ?? 'cash', size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                            wallet.owner == 'husband'
                                ? 'Chồng'
                                : (wallet.owner == 'wife' ? 'Vợ' : 'Chung'),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB))),
                      ),
                      if (wallet.accountNumber != null &&
                          wallet.accountNumber!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(_maskedAccount(wallet.accountNumber),
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF94A3B8))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              Formatters.formatCurrency(wallet.balance),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            IconButton(
              onPressed: () => _showWalletActions(wallet),
              icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 30, height: 36),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(message,
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : const Color(0xFF64748B))),
      ),
    );
  }
}
