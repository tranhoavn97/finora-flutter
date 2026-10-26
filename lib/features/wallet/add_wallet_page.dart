import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/credit_card_palette.dart';
import '../../core/design_system/v8/finora_v8_controls.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../data/models/wallet.dart';
import '../../state/wallet_provider.dart';

class AddWalletPage extends StatefulWidget {
  final String userId;
  final Wallet? wallet;
  const AddWalletPage({super.key, required this.userId, this.wallet});

  @override
  State<AddWalletPage> createState() => _AddWalletPageState();
}

class _AddWalletPageState extends State<AddWalletPage> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _debtCtrl = TextEditingController();
  final _bankCodeCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _statementDayCtrl = TextEditingController(text: '1');
  final _dueDayCtrl = TextEditingController(text: '15');

  String _owner = 'husband';
  String _type = 'cash'; // cash, bank, credit_card
  String _themeColor = 'blue';
  bool _isSaving = false;

  static final _colorOptions = CreditCardPalette.skins.entries
      .map((entry) => (entry.key, entry.value[1]))
      .toList();

  @override
  void initState() {
    super.initState();
    _bankCodeCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _nameCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _balanceCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _limitCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _accountCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.wallet != null) {
      final w = widget.wallet!;
      _nameCtrl.text = w.name;
      _bankCodeCtrl.text = w.bankCode ?? '';
      _accountCtrl.text = w.accountNumber ?? '';
      _owner = w.owner;
      _type = w.type;
      _themeColor = w.themeColor ?? 'blue';
      _limitCtrl.text = w.creditLimit > 0 ? _formatNumber(w.creditLimit) : '';
      _balanceCtrl.text = w.balance > 0 ? _formatNumber(w.balance) : '';
      _debtCtrl.text = w.currentDebt > 0 ? _formatNumber(w.currentDebt) : '';
      _statementDayCtrl.text = '${w.statementDay}';
      _dueDayCtrl.text = '${w.paymentDueDay}';
    }
  }

  static String _formatNumber(int val) {
    final s = val.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _limitCtrl.dispose();
    _debtCtrl.dispose();
    _bankCodeCtrl.dispose();
    _accountCtrl.dispose();
    _statementDayCtrl.dispose();
    _dueDayCtrl.dispose();
    super.dispose();
  }

  int _parseAmount(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên ví hoặc ngân hàng')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isCredit = _type == 'credit_card';
      final bankCode = _bankCodeCtrl.text.trim();
      final selectedBrand = (_type == 'bank' || isCredit)
          ? BankIconRegistry.resolve(bankCode, bankName: _nameCtrl.text.trim())
          : null;
      final account = _accountCtrl.text.trim();
      final statementDay = int.tryParse(_statementDayCtrl.text.trim()) ?? 1;
      final dueDay = int.tryParse(_dueDayCtrl.text.trim()) ?? 15;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (widget.wallet != null) {
        final w = widget.wallet!;
        final creditLimit = _parseAmount(_limitCtrl.text);

        final updatedWallet = Wallet(
          id: w.id,
          name: name,
          type: _type,
          owner: _owner,
          ownerName: _owner == 'husband' ? 'Chồng' : 'Vợ',
          bankCode: bankCode.isNotEmpty ? bankCode : null,
          bankName: selectedBrand?.name,
          accountNumber: account.isNotEmpty ? account : null,
          themeColor: isCredit ? _themeColor : null,
          initialBalance: w.initialBalance,
          balance: w.balance,
          creditLimit: isCredit ? creditLimit : 0,
          initialDebt: w.initialDebt,
          currentDebt: w.currentDebt,
          statementDay: statementDay.clamp(1, 31),
          paymentDueDay: dueDay.clamp(1, 31),
          minimumPaymentPercent: w.minimumPaymentPercent,
          createdAt: w.createdAt,
          updatedAt: now,
        );
        await context
            .read<WalletProvider>()
            .updateWallet(widget.userId, w.id, updatedWallet);
      } else {
        final initialBalance = _parseAmount(_balanceCtrl.text);
        final creditLimit = _parseAmount(_limitCtrl.text);
        final initialDebt = _parseAmount(_debtCtrl.text);

        final wallet = Wallet(
          name: name,
          type: _type,
          owner: _owner,
          ownerName: _owner == 'husband' ? 'Chồng' : 'Vợ',
          bankCode: bankCode.isNotEmpty ? bankCode : null,
          bankName: selectedBrand?.name,
          accountNumber: account.isNotEmpty ? account : null,
          themeColor: isCredit ? _themeColor : null,
          initialBalance: isCredit ? 0 : initialBalance,
          creditLimit: isCredit ? creditLimit : 0,
          initialDebt: isCredit ? initialDebt : 0,
          statementDay: statementDay.clamp(1, 31),
          paymentDueDay: dueDay.clamp(1, 31),
          createdAt: now,
          updatedAt: now,
        );
        await context.read<WalletProvider>().addWallet(widget.userId, wallet);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = _type == 'credit_card';
    final isEditing = widget.wallet != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Scrollable Content
            Positioned.fill(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 68, 16, 110),
                children: [
                  // 1. Live Interactive Card Preview
                  _buildInteractiveCardPreview(isDark, isCredit),
                  const SizedBox(height: 20),

                  // 2. Owner Selector (Chồng / Vợ)
                  _buildSectionHeader('CHỦ SỞ HỮU TÀI KHOẢN', isDark),
                  const SizedBox(height: 8),
                  FinoraSegmentedTabs(
                    labels: const ['Chồng', 'Vợ'],
                    icons: const [Icons.face_rounded, Icons.face_3_rounded],
                    colors: const [Color(0xFF0284C7), Color(0xFFDB2777)],
                    selectedIndex: _owner == 'wife' ? 1 : 0,
                    height: 44,
                    fontSize: 13,
                    onChanged: (idx) {
                      HapticFeedback.selectionClick();
                      setState(() => _owner = idx == 0 ? 'husband' : 'wife');
                    },
                  ),
                  const SizedBox(height: 18),

                  // 3. Wallet Type Selector
                  if (!isEditing) ...[
                    _buildSectionHeader('LOẠI TÀI KHOẢN', isDark),
                    const SizedBox(height: 8),
                    FinoraSegmentedTabs(
                      labels: const ['Tiền mặt', 'Ngân hàng', 'Thẻ Tín dụng'],
                      icons: const [
                        Icons.payments_rounded,
                        Icons.account_balance_rounded,
                        Icons.credit_card_rounded,
                      ],
                      colors: const [
                        Color(0xFF10B981),
                        Color(0xFF0284C7),
                        Color(0xFFD97706),
                      ],
                      selectedIndex: _type == 'cash'
                          ? 0
                          : (_type == 'bank' ? 1 : 2),
                      height: 44,
                      fontSize: 12.5,
                      onChanged: (idx) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _type = idx == 0
                              ? 'cash'
                              : (idx == 1 ? 'bank' : 'credit_card');
                          if (_type == 'cash') {
                            _bankCodeCtrl.clear();
                            if (_nameCtrl.text.isEmpty ||
                                BankIconRegistry.brands.any((b) =>
                                    b.name == _nameCtrl.text.trim())) {
                              _nameCtrl.text = 'Tiền mặt';
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 4. Quick Bank / Cash Presets Selector
                  if (_type == 'cash') ...[
                    _buildSectionHeader('GỢI Ý TÀI KHOẢN TIỀN MẶT', isDark),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildCashPresetChip('Tiền mặt', Icons.account_balance_wallet_rounded, isDark),
                          _buildCashPresetChip('Ống heo tiết kiệm', Icons.savings_rounded, isDark),
                          _buildCashPresetChip('Két sắt gia đình', Icons.lock_outline_rounded, isDark),
                          _buildCashPresetChip('Ví tiền lẻ', Icons.paid_rounded, isDark),
                          _buildCashPresetChip('Quỹ dự phòng', Icons.shield_rounded, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    _buildSectionHeader('CHỌN NHANH NGÂN HÀNG & VÍ ĐIỆN TỬ', isDark),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 64,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: BankIconRegistry.brands
                            .where((b) => b.code != 'cash')
                            .length,
                        itemBuilder: (context, i) {
                          final brand = BankIconRegistry.brands
                              .where((b) => b.code != 'cash')
                              .toList()[i];
                          final isSelected = _bankCodeCtrl.text
                                  .trim()
                                  .toLowerCase() ==
                              brand.code.toLowerCase();

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _bankCodeCtrl.text = brand.code;
                                if (_nameCtrl.text.isEmpty ||
                                    BankIconRegistry.brands.any((b) =>
                                        b.name == _nameCtrl.text.trim()) ||
                                    _nameCtrl.text == 'Tiền mặt') {
                                  _nameCtrl.text = brand.name;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? brand.color.withValues(alpha: isDark ? 0.25 : 0.15)
                                    : (isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? brand.color
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.6 : 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  BankIcon(bankCode: brand.code, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    brand.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? (isDark ? Colors.white : brand.color)
                                          : (isDark
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 5. Wallet Name Input
                  _buildSectionHeader('TÊN VÍ / TÀI KHOẢN', isDark),
                  const SizedBox(height: 8),
                  _buildStyledInput(
                    controller: _nameCtrl,
                    hint: isCredit
                        ? 'Ví dụ: Thẻ Visa Techcombank, VCB Platinum...'
                        : 'Ví dụ: Tiền mặt, Techcombank, MoMo...',
                    icon: Icons.edit_note_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  // 6. Account Number / Card Last 4 Digits
                  if (_type == 'bank' || isCredit) ...[
                    _buildSectionHeader(
                      isCredit ? '4 SỐ CUỐI THẺ TÍN DỤNG' : 'SỐ TÀI KHOẢN NGÂN HÀNG',
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildStyledInput(
                      controller: _accountCtrl,
                      hint: isCredit ? 'Ví dụ: 8899' : 'Nhập số tài khoản...',
                      icon: isCredit ? Icons.pin_rounded : Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 7. Balance or Credit Limit
                  if (!isCredit) ...[
                    if (!isEditing) ...[
                      _buildSectionHeader('SỐ DƯ BAN ĐẦU', isDark),
                      const SizedBox(height: 8),
                      _buildStyledInput(
                        controller: _balanceCtrl,
                        hint: '0',
                        suffix: '₫',
                        icon: Icons.account_balance_wallet_rounded,
                        keyboardType: TextInputType.number,
                        formatters: [DotSeparatorTextInputFormatter()],
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ] else ...[
                    _buildSectionHeader('HẠN MỨC THẺ TÍN DỤNG', isDark),
                    const SizedBox(height: 8),
                    _buildStyledInput(
                      controller: _limitCtrl,
                      hint: 'Ví dụ: 20.000.000',
                      suffix: '₫',
                      icon: Icons.speed_rounded,
                      keyboardType: TextInputType.number,
                      formatters: [DotSeparatorTextInputFormatter()],
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    if (!isEditing) ...[
                      _buildSectionHeader('DƯ NỢ BAN ĐẦU (NẾU CÓ)', isDark),
                      const SizedBox(height: 8),
                      _buildStyledInput(
                        controller: _debtCtrl,
                        hint: '0',
                        suffix: '₫',
                        icon: Icons.receipt_long_rounded,
                        keyboardType: TextInputType.number,
                        formatters: [DotSeparatorTextInputFormatter()],
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Statement Day & Due Day Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('NGÀY SAO KÊ', isDark),
                              const SizedBox(height: 8),
                              _buildStyledInput(
                                controller: _statementDayCtrl,
                                hint: '1',
                                icon: Icons.calendar_month_rounded,
                                keyboardType: TextInputType.number,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('HẠN THANH TOÁN', isDark),
                              const SizedBox(height: 8),
                              _buildStyledInput(
                                controller: _dueDayCtrl,
                                hint: '15',
                                icon: Icons.event_available_rounded,
                                keyboardType: TextInputType.number,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Color Skins for all wallets (Debit / Cash / Credit)
                  _buildSectionHeader('MÀU SẮC THẺ HIỂN THỊ', isDark),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _colorOptions.length,
                      itemBuilder: (context, i) {
                        final opt = _colorOptions[i];
                        final isSelected = _themeColor == opt.$1;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _themeColor = opt.$1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: opt.$2,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: opt.$2.withValues(alpha: isSelected ? 0.60 : 0.20),
                                  blurRadius: isSelected ? 10 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Floating Frosted Glass Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildFloatingHeader(isDark, isEditing),
            ),

            // Floating Frosted Glass Save Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFloatingSaveButton(isDark, isEditing),
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
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildCashPresetChip(String name, IconData icon, bool isDark) {
    final isSelected = _nameCtrl.text.trim() == name;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _nameCtrl.text = name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F6E56).withValues(alpha: isDark ? 0.30 : 0.15)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : (isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F6E56))
                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? suffix,
    required bool isDark,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: isDark ? 0.85 : 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isDark ? 0.12 : 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: formatters,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffix != null)
            Text(
              suffix,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCardPreview(bool isDark, bool isCredit) {
    final bankCode = _bankCodeCtrl.text.trim();
    final brand = BankIconRegistry.resolve(bankCode, bankName: _nameCtrl.text.trim());
    final isCash = _type == 'cash';
    final cardColors = (isCredit && CreditCardPalette.skins.containsKey(_themeColor))
        ? CreditCardPalette.skins[_themeColor]!
        : (isCash
            ? [const Color(0xFF065F46), const Color(0xFF0F766E), const Color(0xFF10B981)]
            : [
                Color.lerp(const Color(0xFF080C14), brand.color, 0.55)!,
                Color.lerp(const Color(0xFF141A28), brand.color, 0.85)!,
                Color.lerp(const Color(0xFF04060A), brand.color, 0.40)!,
              ]);

    final rawBalance = isCredit
        ? (_parseAmount(_limitCtrl.text) - _parseAmount(_debtCtrl.text))
        : _parseAmount(_balanceCtrl.text);

    final displayAccount = _accountCtrl.text.isNotEmpty
        ? '•••• •••• •••• ${_accountCtrl.text}'
        : (isCash ? 'TIỀN MẶT' : '•••• •••• •••• 8899');

    final displayName = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text
        : (isCash ? 'Ví Tiền Mặt' : (brand.name.isNotEmpty ? brand.name : 'Ngân hàng'));

    return Container(
      height: 184,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: cardColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColors.last.withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (!isCash && brand.assetPath != null)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              brand.assetPath!,
                              width: 22,
                              height: 22,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCash ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                          ),
                          child: Icon(
                            isCash ? Icons.payments_rounded : Icons.credit_card_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        isCash ? 'TIỀN MẶT' : brand.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        isCredit
                            ? 'CREDIT CARD'
                            : (isCash ? 'CASH' : 'DEBIT CARD'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.contactless_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),

              // Middle: Name & Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatVND(rawBalance),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),

              // Bottom: Number & Owner Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayAccount,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _owner == 'wife' ? 'VỢ' : 'CHỒNG',
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
      ),
    );
  }

  Widget _buildFloatingHeader(bool isDark, bool isEditing) {
    final pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: pageBg.withValues(alpha: isDark ? 0.82 : 0.86),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.08 : 0.06),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing ? 'Chỉnh sửa ví / tài khoản' : 'Thêm ví / tài khoản',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSaveButton(bool isDark, bool isEditing) {
    final pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.paddingOf(context).bottom + 12,
          ),
          decoration: BoxDecoration(
            color: pageBg.withValues(alpha: isDark ? 0.85 : 0.90),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.08 : 0.06),
                width: 0.8,
              ),
            ),
          ),
          child: InkWell(
            onTap: _isSaving ? null : _save,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.38),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Lưu thay đổi' : 'Tạo ví mới',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
