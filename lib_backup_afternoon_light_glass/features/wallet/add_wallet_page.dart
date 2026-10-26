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

  String _owner = 'husband';
  String _type = 'cash'; // cash, bank, credit_card
  String _themeColor = 'blue';
  bool _isSaving = false;

  static const _colorOptions = <(String, Color)>[
    ('blue', Color(0xFF1E57A8)),
    ('purple', Color(0xFF4C1D95)),
    ('rose', Color(0xFFE11D48)),
    ('emerald', Color(0xFF059669)),
    ('dark', Color(0xFF1A1A1A)),
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
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final isCredit = _type == 'credit_card';
      final bankCode = _bankCodeCtrl.text.trim();
      final account = _accountCtrl.text.trim();
      final now = DateTime.now().millisecondsSinceEpoch;

      if (widget.wallet != null) {
        final w = widget.wallet!;
        final updatedWallet = Wallet(
          id: w.id,
          name: name,
          type: _type,
          owner: _owner,
          ownerName: _owner == 'husband' ? 'Chồng' : 'Vợ',
          bankCode: bankCode.isNotEmpty ? bankCode : null,
          accountNumber: account.isNotEmpty ? account : null,
          themeColor: isCredit ? _themeColor : null,
          initialBalance: w.initialBalance,
          balance: w.balance,
          creditLimit: w.creditLimit,
          initialDebt: w.initialDebt,
          currentDebt: w.currentDebt,
          statementDay: w.statementDay,
          paymentDueDay: w.paymentDueDay,
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
          accountNumber: account.isNotEmpty ? account : null,
          themeColor: isCredit ? _themeColor : null,
          initialBalance: isCredit ? 0 : initialBalance,
          creditLimit: isCredit ? creditLimit : 0,
          initialDebt: isCredit ? initialDebt : 0,
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
                      ('husband', 'Ví của Chồng'),
                      ('wife', 'Ví của Vợ'),
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
                        ('credit_card', 'Thẻ TD'),
                      ],
                      selected: _type,
                      onChanged: (v) => setState(() => _type = v),
                    ),
                  ),
                _field(
                  label: 'Tên ví / ngân hàng',
                  child: GlassTextField(
                    controller: _nameCtrl,
                    hint: 'Ví dụ: Ví MoMo, Vietcombank...',
                  ),
                ),
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
                  if (_type == 'bank') ...[
                    _field(
                      label: 'Mã ngân hàng',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlassTextField(
                            controller: _bankCodeCtrl,
                            hint: 'Mã: TCB, VCB, BIDV...',
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 48,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (final code in BankIconRegistry.registeredCodes)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _bankCodeCtrl.text = code;
                                          if (_nameCtrl.text.isEmpty ||
                                              BankIconRegistry.registeredCodes.contains(_nameCtrl.text.trim().toUpperCase())) {
                                            _nameCtrl.text = code;
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _bankCodeCtrl.text.trim().toUpperCase() == code
                                                ? AppColors.accent
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: BankIcon(bankCode: code, size: 36),
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
                      label: 'Số tài khoản',
                      child: GlassTextField(
                        controller: _accountCtrl,
                        hint: 'Nhập số tài khoản...',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ] else ...[
                  if (!isEditing) ...[
                    _field(
                      label: 'Hạn mức thẻ tín dụng',
                      child: GlassTextField(
                        controller: _limitCtrl,
                        hint: '0 ₫',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    _field(
                      label: 'Dư nợ hiện tại',
                      child: GlassTextField(
                        controller: _debtCtrl,
                        hint: '0 ₫',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                  _field(
                    label: '4 số cuối của thẻ',
                    child: GlassTextField(
                      controller: _accountCtrl,
                      hint: 'Ví dụ: 1234',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  _field(
                    label: 'Màu sắc thẻ hiển thị',
                    child: Row(
                      children: [
                        for (final opt in _colorOptions) ...[
                          GestureDetector(
                            onTap: () =>
                                setState(() => _themeColor = opt.$1),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: opt.$2,
                                border: Border.all(
                                  color: _themeColor == opt.$1
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
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
                AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md + MediaQuery.of(context).padding.bottom),
            child: PrimaryButton(
              onPressed: _isSaving ? null : _save,
              expand: true,
              child: _isSaving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Lưu ví',
                      style: TextStyle(fontWeight: FontWeight.w600)),
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
          Text(label,
              style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}
