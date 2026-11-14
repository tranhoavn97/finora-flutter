import '../../core/widgets/finora_modal_scope.dart';
import '../../core/widgets/finora_notice.dart';
import '../../core/widgets/fresh_design.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/credit_card_palette.dart';
import '../../core/design_system/v8/finora_v8_controls.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../data/models/wallet.dart';
import '../../state/theme_studio_controller.dart';
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
  final _iconUrlCtrl = TextEditingController();
  final _statementDayCtrl = TextEditingController(text: '1');
  final _dueDayCtrl = TextEditingController(text: '15');

  String _owner = 'husband';
  String _type = 'cash'; // cash, bank, credit_card
  String _themeColor = 'blue';
  String? _customIconUrl;
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
    _iconUrlCtrl.addListener(() {
      final text = _iconUrlCtrl.text.trim();
      if (text.isNotEmpty) {
        _customIconUrl = text;
      } else if (_customIconUrl != null &&
          !_customIconUrl!.startsWith('data:image')) {
        _customIconUrl = null;
      }
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
      _customIconUrl = w.iconUrl;
      if (w.iconUrl != null && !w.iconUrl!.startsWith('data:image')) {
        _iconUrlCtrl.text = w.iconUrl!;
      }
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
    _iconUrlCtrl.dispose();
    _statementDayCtrl.dispose();
    _dueDayCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBankImageFromDevice() async {
    try {
      HapticFeedback.selectionClick();
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final mime =
          picked.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      if (!mounted) return;
      setState(() {
        _iconUrlCtrl.clear();
        _customIconUrl = dataUri;
      });
    } catch (e) {
      if (!mounted) return;
      FinoraNotice.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải ảnh: $e')),
      );
    }
  }

  Future<void> _openPresetBankLogoSheet(bool isDark) async {
    HapticFeedback.selectionClick();
    final presetLogos = BankIconRegistry.brands
        .where((b) => b.assetPath != null && b.assetPath!.isNotEmpty)
        .toList();
    String searchQuery = '';
    String selectedGroup = 'all'; // all, bank, digital, wallet

    const ewalletCodes = {
      'momo',
      'zalo',
      'vnpay',
      'shopeepay',
      'viettelmoney',
      'vnptmoney',
      'payoo',
      'vtcpay',
      'foxpay',
      'mobifonemoney',
      'smartpay',
      '9pay',
      'appotapay',
      'vinid',
      'homecredit',
      'fecredit',
      'hdsaison',
      'miraeasset',
    };
    const digitalCodes = {
      'cake',
      'timo',
      'tnex',
      'ubank',
      'liobank',
      'vikki',
    };

    final chosen = await showModalBottomSheet<BankBrand>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = presetLogos.where((b) {
              if (selectedGroup == 'wallet' && !ewalletCodes.contains(b.code)) {
                return false;
              }
              if (selectedGroup == 'digital' && !digitalCodes.contains(b.code)) {
                return false;
              }
              if (selectedGroup == 'bank' &&
                  (ewalletCodes.contains(b.code) ||
                      digitalCodes.contains(b.code))) {
                return false;
              }
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.trim().toLowerCase();
              return b.name.toLowerCase().contains(q) ||
                  b.code.toLowerCase().contains(q);
            }).toList();

            final sheetBrandPrimary =
                Provider.of<ThemeStudioController?>(ctx, listen: false)
                        ?.resolvedPrimary ??
                    const Color(0xFF059669);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.78,
              ),
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                MediaQuery.viewInsetsOf(ctx).bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ngân hàng & Ví điện tử Việt Nam',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Đầy đủ ${presetLogos.length} ngân hàng, ngân hàng số & ví điện tử',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FinoraCircleIconButton(
                          icon: Icons.close_rounded,
                          size: 32,
                          iconSize: 18,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Search field
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (v) =>
                                  setSheetState(() => searchQuery = v),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Tìm ngân hàng, ví (VD: NCB, Vietcombank, MoMo...)',
                                hintStyle: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final tab in const [
                            ('all', 'Tất cả'),
                            ('bank', 'Ngân hàng'),
                            ('digital', 'Ngân hàng số'),
                            ('wallet', 'Ví điện tử & TC'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => setSheetState(
                                    () => selectedGroup = tab.$1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selectedGroup == tab.$1
                                        ? _activeTypeColor(sheetBrandPrimary)
                                        : (isDark
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tab.$2,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: selectedGroup == tab.$1
                                          ? Colors.white
                                          : (isDark
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.86,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, idx) {
                          final b = filtered[idx];
                          final selected = _customIconUrl == b.assetPath ||
                              _bankCodeCtrl.text.trim().toLowerCase() == b.code;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(ctx, b),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? b.color
                                        .withValues(alpha: isDark ? 0.24 : 0.12)
                                    : (isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? b.color
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFE2E8F0)),
                                  width: selected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  BankIcon(
                                    bankCode: b.code,
                                    bankName: b.name,
                                    customIconUrl: b.assetPath,
                                    size: 38,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    b.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (chosen != null && mounted) {
      setState(() {
        _bankCodeCtrl.text = chosen.code;
        _customIconUrl = chosen.assetPath;
        _iconUrlCtrl.text = chosen.assetPath ?? '';
        if (_nameCtrl.text.trim().isEmpty ||
            BankIconRegistry.brands
                .any((b) => b.name == _nameCtrl.text.trim()) ||
            _nameCtrl.text.trim() == 'Tiền mặt') {
          _nameCtrl.text = chosen.name;
        }
      });
    }
  }

  int _parseAmount(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      FinoraNotice.of(context).showSnackBar(
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

      final resolvedIconUrl = (_customIconUrl != null &&
              _customIconUrl!.trim().isNotEmpty)
          ? _customIconUrl!.trim()
          : (_iconUrlCtrl.text.trim().isNotEmpty
              ? _iconUrlCtrl.text.trim()
              : null);

      if (widget.wallet != null) {
        final w = widget.wallet!;
        final creditLimit = _parseAmount(_limitCtrl.text);
        final targetBalance = _parseAmount(_balanceCtrl.text);
        final targetDebt = _parseAmount(_debtCtrl.text);
        final editedInitialBalance = w.hasInitialBalance
            ? (targetBalance == w.balance
                ? w.initialBalance
                : w.initialBalance + (targetBalance - w.balance))
            : w.initialBalance;
        final editedBalance = targetBalance == w.balance ? w.balance : targetBalance;
        final editedInitialDebt = w.hasInitialDebt
            ? (targetDebt == w.currentDebt
                ? w.initialDebt
                : (w.initialDebt + (targetDebt - w.currentDebt))
                    .clamp(0, 1 << 62))
            : w.initialDebt;
        final editedCurrentDebt =
            targetDebt == w.currentDebt ? w.currentDebt : targetDebt;

        final updatedWallet = Wallet(
          id: w.id,
          name: name,
          type: _type,
          owner: _owner,
          ownerName: _owner == 'husband' ? 'Chồng' : 'Vợ',
          bankCode: bankCode.isNotEmpty ? bankCode : null,
          bankName: selectedBrand?.name,
          accountNumber: account.isNotEmpty ? account : null,
          themeColor: _themeColor,
          iconUrl: resolvedIconUrl,
          initialBalance: isCredit ? 0 : editedInitialBalance,
          hasInitialBalance: w.hasInitialBalance,
          balance: isCredit ? 0 : editedBalance,
          creditLimit: isCredit ? creditLimit : 0,
          initialDebt: isCredit ? editedInitialDebt : 0,
          hasInitialDebt: w.hasInitialDebt,
          currentDebt: isCredit ? editedCurrentDebt : 0,
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
          themeColor: _themeColor,
          iconUrl: resolvedIconUrl,
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
        FinoraNotice.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addQuickBalance(int delta, bool isCredit) {
    HapticFeedback.selectionClick();
    final ctrl = isCredit ? _limitCtrl : _balanceCtrl;
    final current = _parseAmount(ctrl.text);
    final next = (current + delta).clamp(0, 999000000000);
    ctrl.text = next > 0 ? _formatNumber(next) : '';
    setState(() {});
  }

  Color _activeTypeColor(Color brandPrimary) {
    if (_type == 'cash') return brandPrimary;
    if (_type == 'credit_card') return const Color(0xFFD97706);
    return const Color(0xFF0284C7);
  }

  @override
  Widget build(BuildContext context) {
    return FinoraModalScope(
      child: Theme(
        data: FinoraModalScope.opaqueModalTheme(context),
        child: Builder(builder: _buildScopedContent),
      ),
    );
  }

  Widget _buildScopedContent(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final brandPrimary = studio?.resolvedPrimary ?? const Color(0xFF0F6E56);
    final brandSecondary =
        studio?.resolvedSecondary ?? const Color(0xFF10B981);
    final isCredit = _type == 'credit_card';
    final isEditing = widget.wallet != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _activeTypeColor(brandPrimary);

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: isEditing ? 'Chỉnh sửa ví / tài khoản' : 'Thêm ví / tài khoản',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          // Scrollable Content (AddTransactionPage "modal ghi chép" layout)
          Positioned.fill(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                14,
                GlassScaffold.topInset(context, 10),
                14,
                MediaQuery.paddingOf(context).bottom + 96,
              ),
              children: [
                // 1. Top Segmented Type Selector (like AddTransactionPage type tabs)
                if (!isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: FinoraSegmentedTabs(
                      labels: const ['Tiền mặt', 'Ngân hàng', 'Thẻ Tín dụng'],
                      icons: const [
                        Icons.payments_rounded,
                        Icons.account_balance_rounded,
                        Icons.credit_card_rounded,
                      ],
                      colors: [
                        brandPrimary,
                        const Color(0xFF0284C7),
                        const Color(0xFFD97706),
                      ],
                        selectedIndex:
                            _type == 'cash' ? 0 : (_type == 'bank' ? 1 : 2),
                        height: 40,
                        fontSize: 12.2,
                        transparentBackground: true,
                        onChanged: (idx) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _type = idx == 0
                                ? 'cash'
                                : (idx == 1 ? 'bank' : 'credit_card');
                            if (_type == 'cash') {
                              _bankCodeCtrl.clear();
                              if (_nameCtrl.text.isEmpty ||
                                  BankIconRegistry.brands.any(
                                      (b) => b.name == _nameCtrl.text.trim())) {
                                _nameCtrl.text = 'Tiền mặt';
                              }
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 2. Hero Amount / Balance Input Card (matching AddTransactionPage hero)
                  if (!isEditing || isCredit) ...[
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accent.withValues(alpha: isDark ? 0.40 : 0.25),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                accent.withValues(alpha: isDark ? 0.16 : 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          isCredit
                                              ? 'HẠN MỨC TÍN DỤNG'
                                              : 'SỐ DƯ BAN ĐẦU',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _owner == 'wife' ? 'Ví của Vợ' : 'Ví của Chồng',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: IntrinsicWidth(
                                  child: TextField(
                                    controller:
                                        isCredit ? _limitCtrl : _balanceCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [
                                      DotSeparatorTextInputFormatter()
                                    ],
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: (isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A))
                                            .withValues(alpha: 0.25),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '₫',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                for (final chip in const [
                                  ('+500k', 500000),
                                  ('+1tr', 1000000),
                                  ('+5tr', 5000000),
                                  ('+10tr', 10000000),
                                  ('+50tr', 50000000),
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      onTap: () =>
                                          _addQuickBalance(chip.$2, isCredit),
                                      borderRadius: BorderRadius.circular(100),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4.5),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(
                                              alpha: isDark ? 0.16 : 0.08),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          border: Border.all(
                                            color:
                                                accent.withValues(alpha: 0.28),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          chip.$1,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 3. Compact Live Interactive Card Preview
                  _buildInteractiveCardPreview(isDark, isCredit),
                  const SizedBox(height: 14),

                  // 4. Bento Form Card (Owner + Quick Presets + Name + Account + Colors)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.20 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Owner Selector (Chồng / Vợ)
                        _buildSectionHeader('CHỦ SỞ HỮU TÀI KHOẢN', isDark),
                        const SizedBox(height: 8),
                        FinoraSegmentedTabs(
                          labels: const ['Chồng', 'Vợ'],
                          icons: const [
                            Icons.face_rounded,
                            Icons.face_3_rounded
                          ],
                          colors: const [Color(0xFF0284C7), Color(0xFFDB2777)],
                          selectedIndex: _owner == 'wife' ? 1 : 0,
                          height: 42,
                          fontSize: 12.5,
                          onChanged: (idx) {
                            HapticFeedback.selectionClick();
                            setState(
                                () => _owner = idx == 0 ? 'husband' : 'wife');
                          },
                        ),
                        const SizedBox(height: 16),

                        // Quick Bank / Cash Presets Selector
                        if (_type == 'cash') ...[
                          _buildSectionHeader(
                              'GỢI Ý TÀI KHOẢN TIỀN MẶT', isDark),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildCashPresetChip(
                                    'Tiền mặt',
                                    Icons.account_balance_wallet_rounded,
                                    isDark),
                                _buildCashPresetChip('Ống heo tiết kiệm',
                                    Icons.savings_rounded, isDark),
                                _buildCashPresetChip('Két sắt gia đình',
                                    Icons.lock_outline_rounded, isDark),
                                _buildCashPresetChip(
                                    'Ví tiền lẻ', Icons.paid_rounded, isDark),
                                _buildCashPresetChip('Quỹ dự phòng',
                                    Icons.shield_rounded, isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildSectionHeader(
                                  'CHỌN NHANH NGÂN HÀNG & VÍ ĐIỆN TỬ',
                                  isDark,
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => _openPresetBankLogoSheet(isDark),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(
                                      alpha: isDark ? 0.22 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        size: 13,
                                        color: accent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tìm tất cả (66+)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 54,
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
                                final isSelected =
                                    _bankCodeCtrl.text.trim().toLowerCase() ==
                                        brand.code.toLowerCase();

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _bankCodeCtrl.text = brand.code;
                                      if (_nameCtrl.text.isEmpty ||
                                          BankIconRegistry.brands.any((b) =>
                                              b.name ==
                                              _nameCtrl.text.trim()) ||
                                          _nameCtrl.text == 'Tiền mặt') {
                                        _nameCtrl.text = brand.name;
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? brand.color.withValues(
                                              alpha: isDark ? 0.25 : 0.14)
                                          : (isDark
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? brand.color
                                            : (isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.10)
                                                : const Color(0xFFE2E8F0)),
                                        width: isSelected ? 1.5 : 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        BankIcon(bankCode: brand.code, size: 26),
                                        const SizedBox(width: 8),
                                        Text(
                                          brand.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? (isDark
                                                    ? Colors.white
                                                    : brand.color)
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
                          const SizedBox(height: 16),
                        ],

                        // Wallet Name Input
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
                        const SizedBox(height: 14),

                        // Custom Bank / Wallet Image Icon Picker (Synced with Web)
                        _buildSectionHeader(
                          'ICON NGÂN HÀNG / VÍ BẰNG ẢNH (ĐỒNG BỘ WEB)',
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withValues(alpha: 0.72)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  BankIcon(
                                    bankCode: _bankCodeCtrl.text.trim(),
                                    bankName: _nameCtrl.text.trim(),
                                    customIconUrl: _customIconUrl,
                                    size: 46,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          onTap: _pickBankImageFromDevice,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 7.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accent.withValues(
                                                alpha: isDark ? 0.22 : 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: accent.withValues(
                                                    alpha: 0.45),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.upload_file_rounded,
                                                  size: 15,
                                                  color: accent,
                                                ),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    'Tải ảnh lên',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: accent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          onTap: () =>
                                              _openPresetBankLogoSheet(isDark),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 7.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1E293B)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.14)
                                                    : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.photo_library_outlined,
                                                  size: 15,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF334155),
                                                ),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    'Kho logo NH',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isDark
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF334155),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (_customIconUrl != null &&
                                            _customIconUrl!.isNotEmpty)
                                          InkWell(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setState(() {
                                                _customIconUrl = null;
                                                _iconUrlCtrl.clear();
                                              });
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 7.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE11D48)
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 15,
                                                color: Color(0xFFE11D48),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildStyledInput(
                                controller: _iconUrlCtrl,
                                hint:
                                    'Hoặc dán URL ảnh icon (https://... hoặc assets/banks/...)',
                                icon: Icons.link_rounded,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Account Number / Card Last 4 Digits
                        if (_type == 'bank' || isCredit) ...[
                          _buildSectionHeader(
                            isCredit
                                ? '4 SỐ CUỐI THẺ TÍN DỤNG'
                                : 'SỐ TÀI KHOẢN NGÂN HÀNG',
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildStyledInput(
                            controller: _accountCtrl,
                            hint: isCredit
                                ? 'Ví dụ: 8899'
                                : 'Nhập số tài khoản...',
                            icon: isCredit
                                ? Icons.pin_rounded
                                : Icons.numbers_rounded,
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Credit Card Debt & Billing Days
                        if (isCredit) ...[
                          if (!isEditing) ...[
                            _buildSectionHeader(
                                'DƯ NỢ BAN ĐẦU (NẾU CÓ)', isDark),
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
                            const SizedBox(height: 14),
                          ],
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
                                    _buildSectionHeader(
                                        'HẠN THANH TOÁN', isDark),
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
                          const SizedBox(height: 16),
                        ],

                        // Color Skins for all wallets
                        _buildSectionHeader('MÀU SẮC THẺ HIỂN THỊ', isDark),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
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
                                  width: 36,
                                  height: 36,
                                  margin: const EdgeInsets.only(right: 10),
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
                                        color: opt.$2.withValues(
                                            alpha: isSelected ? 0.55 : 0.18),
                                        blurRadius: isSelected ? 8 : 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 17,
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
                ],
              ),
            ),

            // Floating Frosted Glass Save Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFloatingSaveButton(
                  isDark, isEditing, brandPrimary, brandSecondary),
            ),
          ],
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
    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    final brandPrimary = studio?.resolvedPrimary ?? const Color(0xFF0F6E56);
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
              ? brandPrimary.withValues(alpha: isDark ? 0.28 : 0.14)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? brandPrimary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? brandPrimary
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : brandPrimary)
                    : (isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569)),
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
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCardPreview(bool isDark, bool isCredit) {
    final bankCode = _bankCodeCtrl.text.trim();
    final brand =
        BankIconRegistry.resolve(bankCode, bankName: _nameCtrl.text.trim());
    final isCash = _type == 'cash';
    final studio = Provider.of<ThemeStudioController?>(context, listen: false);
    final brandPrimary = studio?.resolvedPrimary ?? const Color(0xFF0F6E56);
    final cardColors =
        (isCredit && CreditCardPalette.skins.containsKey(_themeColor))
            ? CreditCardPalette.skins[_themeColor]!
            : (isCash
                ? [
                    Color.lerp(brandPrimary, Colors.black, 0.28)!,
                    brandPrimary,
                    Color.lerp(brandPrimary, Colors.white, 0.14)!,
                  ]
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
        : (isCash
            ? 'Ví Tiền Mặt'
            : (brand.name.isNotEmpty ? brand.name : 'Ngân hàng'));

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
                  Expanded(
                    child: Row(
                      children: [
                        if (_customIconUrl != null &&
                            _customIconUrl!.trim().isNotEmpty)
                          BankIcon(
                            bankCode: bankCode,
                            bankName: _nameCtrl.text.trim(),
                            customIconUrl: _customIconUrl,
                            size: 24,
                          )
                        else if (!isCash && brand.assetPath != null)
                          Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.25),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.65),
                                width: 1.0,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                brand.assetPath!,
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCash
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF0284C7),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.55),
                                width: 1.0,
                              ),
                            ),
                            child: Icon(
                              isCash
                                  ? Icons.payments_rounded
                                  : Icons.credit_card_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isCash ? 'TIỀN MẶT' : brand.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCredit ? 'CREDIT' : (isCash ? 'CASH' : 'DEBIT'),
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
                  Flexible(
                    child: Text(
                      displayAccount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
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

  Widget _buildFloatingSaveButton(
      bool isDark, bool isEditing, Color brandPrimary, Color brandSecondary) {
    final pageBg = isDark ? const Color(0xFF0F172A) : FreshColors.background;
    final saveStart = _type == 'credit_card'
        ? const Color(0xFFD97706)
        : (_type == 'bank' ? const Color(0xFF0284C7) : brandPrimary);
    final saveEnd = _type == 'credit_card'
        ? const Color(0xFFB45309)
        : (_type == 'bank' ? const Color(0xFF0369A1) : brandSecondary);
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
                gradient: LinearGradient(
                  colors: [saveStart, saveEnd],
                ),
                boxShadow: [
                  BoxShadow(
                    color: saveStart.withValues(alpha: 0.36),
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
