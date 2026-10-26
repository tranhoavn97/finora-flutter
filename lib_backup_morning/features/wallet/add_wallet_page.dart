import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
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

  static const _colorOptions = <(String, Color)>[
    ('blue', Color(0xFF2563EB)),
    ('purple', Color(0xFF7C3AED)),
    ('rose', Color(0xFFE11D48)),
    ('emerald', Color(0xFF059669)),
    ('dark', Color(0xFF1E293B)),
  ];

  @override
  void initState() {
    super.initState();
    _bankCodeCtrl.addListener(() {
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
      _limitCtrl.text = w.creditLimit > 0 ? '${w.creditLimit}' : '';
      _statementDayCtrl.text = '${w.statementDay}';
      _dueDayCtrl.text = '${w.paymentDueDay}';
    }
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
        final creditLimit = int.tryParse(_limitCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? w.creditLimit;

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
        await context.read<WalletProvider>().updateWallet(widget.userId, w.id, updatedWallet);
      } else {
        final initialBalance = int.tryParse(_balanceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final creditLimit = int.tryParse(_limitCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final initialDebt = int.tryParse(_debtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = _type == 'credit_card';
    final isEditing = widget.wallet != null;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: isEditing ? 'Chỉnh sửa ví / tài khoản' : 'Thêm ví / tài khoản',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
              children: [
                _field(
                  label: 'Chủ sở hữu',
                  child: SegmentedControl(
                    options: const [
                      ('husband', '👨 Ví của Chồng'),
                      ('wife', '👩 Ví của Vợ'),
                    ],
                    selected: _owner,
                    onChanged: (v) => setState(() => _owner = v),
                  ),
                ),
                if (!isEditing)
                  _field(
                    label: 'Loại tài khoản',
                    child: SegmentedControl(
                      options: const [
                        ('cash', 'Tiền mặt'),
                        ('bank', 'Ngân hàng'),
                        ('credit_card', 'Thẻ Tín dụng'),
                      ],
                      selected: _type,
                      onChanged: (v) => setState(() => _type = v),
                    ),
                  ),
                _field(
                  label: 'Tên ví / ngân hàng',
                  child: GlassTextField(
                    controller: _nameCtrl,
                    hint: isCredit ? 'Ví dụ: Thẻ Techcombank Visa, VCB...' : 'Ví dụ: Ví Tiền mặt, Techcombank, MoMo...',
                  ),
                ),
                if (_type == 'bank' || isCredit) ...[
                  _field(
                    label: 'Chọn nhanh ngân hàng',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 52,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              for (final brand in BankIconRegistry.brands.where((b) => b.code != 'cash'))
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _bankCodeCtrl.text = brand.code;
                                        if (_nameCtrl.text.isEmpty ||
                                            BankIconRegistry.brands.any((b) => b.name == _nameCtrl.text.trim())) {
                                          _nameCtrl.text = brand.name;
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _bankCodeCtrl.text.trim().toLowerCase() == brand.code.toLowerCase()
                                              ? const Color(0xFF2563EB)
                                              : Colors.transparent,
                                          width: 2.5,
                                        ),
                                      ),
                                      child: BankIcon(bankCode: brand.code, size: 40),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _field(
                    label: isCredit ? '4 số cuối của thẻ' : 'Số tài khoản',
                    child: GlassTextField(
                      controller: _accountCtrl,
                      hint: isCredit ? 'Ví dụ: 8899' : 'Nhập số tài khoản...',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
                if (!isCredit) ...[
                  if (!isEditing)
                    _field(
                      label: 'Số dư ban đầu',
                      child: GlassTextField(
                        controller: _balanceCtrl,
                        hint: '0 ₫',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                ] else ...[
                  _field(
                    label: 'Hạn mức thẻ tín dụng',
                    child: GlassTextField(
                      controller: _limitCtrl,
                      hint: 'Ví dụ: 50.000.000 ₫',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  if (!isEditing)
                    _field(
                      label: 'Dư nợ ban đầu (nếu có)',
                      child: GlassTextField(
                        controller: _debtCtrl,
                        hint: '0 ₫',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: 'Ngày sao kê (1-31)',
                          child: GlassTextField(
                            controller: _statementDayCtrl,
                            hint: '1',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          label: 'Hạn thanh toán (1-31)',
                          child: GlassTextField(
                            controller: _dueDayCtrl,
                            hint: '15',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _field(
                    label: 'Màu sắc thẻ hiển thị',
                    child: Row(
                      children: [
                        for (final opt in _colorOptions) ...[
                          GestureDetector(
                            onTap: () => setState(() => _themeColor = opt.$1),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: opt.$2,
                                border: Border.all(
                                  color: _themeColor == opt.$1 ? Colors.white : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: _themeColor == opt.$1
                                    ? [
                                        BoxShadow(
                                          color: opt.$2.withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.of(context).padding.bottom,
            ),
            child: PrimaryButton(
              onPressed: _isSaving ? null : _save,
              expand: true,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'Lưu thay đổi' : 'Thêm ví mới',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({required String label, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}
