import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
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
  String _themeColor = '#3157D5';
  bool _isSaving = false;

  static const _colorOptions = <(String, Color)>[
    ('#3157D5', Color(0xFF3157D5)),
    ('#0891B2', Color(0xFF0891B2)),
    ('#10B981', Color(0xFF10B981)),
    ('#EA0029', Color(0xFFEA0029)),
    ('#F47D22', Color(0xFFF47D22)),
    ('#8E2B88', Color(0xFF8E2B88)),
    ('#A50064', Color(0xFFA50064)),
    ('#1E293B', Color(0xFF1E293B)),
    ('#D4AF37', Color(0xFFD4AF37)),
    ('#64748B', Color(0xFF64748B)),
  ];

  static String _normalizeThemeColor(String? value) {
    const legacy = {
      'blue': '#3157D5',
      'ocean': '#075985',
      'cyan': '#0891B2',
      'rose': '#E11D48',
      'emerald': '#10B981',
      'dark': '#1E293B',
    };
    return legacy[value] ?? value ?? '#3157D5';
  }

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
      _themeColor = _normalizeThemeColor(w.themeColor);
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
      final bank = BankIconRegistry.resolve(bankCode.isEmpty ? name : bankCode);
      final account = _accountCtrl.text.trim();
      final now = DateTime.now().millisecondsSinceEpoch;

      if (widget.wallet != null) {
        final w = widget.wallet!;
        final updatedWallet = Wallet(
          id: w.id,
          name: name,
          type: _type,
          owner: _owner,
          ownerName: _owner == 'husband'
              ? 'Chồng'
              : (_owner == 'wife' ? 'Vợ' : 'Chung'),
          bankCode: bankCode.isNotEmpty ? bankCode : null,
          bankName: bankCode.isNotEmpty ? bank.shortName : null,
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
        await context
            .read<WalletProvider>()
            .updateWallet(widget.userId, w.id, updatedWallet);
      } else {
        final initialBalance =
            int.tryParse(_balanceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                0;
        final creditLimit =
            int.tryParse(_limitCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                0;
        final initialDebt =
            int.tryParse(_debtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        final wallet = Wallet(
          name: name,
          type: _type,
          owner: _owner,
          ownerName: _owner == 'husband'
              ? 'Chồng'
              : (_owner == 'wife' ? 'Vợ' : 'Chung'),
          bankCode: bankCode.isNotEmpty ? bankCode : null,
          bankName: bankCode.isNotEmpty ? bank.shortName : null,
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

    return GlassScaffold(
      appBar: GlassTopBar(
        title: isEditing ? 'Chỉnh sửa ví / tài khoản' : 'Thêm ví / tài khoản',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Overline('CHỦ SỞ HỮU'),
                        const SizedBox(height: 6),
                        SegmentedControl(
                          options: const [
                            ('husband', 'Chồng'),
                            ('wife', 'Vợ'),
                          ],
                          selected: _owner,
                          onChanged: (v) => setState(() => _owner = v),
                        ),
                        if (!isEditing) ...[
                          const SizedBox(height: 14),
                          const Overline('LOẠI TÀI KHOẢN'),
                          const SizedBox(height: 6),
                          SegmentedControl(
                            options: const [
                              ('cash', 'Tiền mặt'),
                              ('bank', 'Ngân hàng'),
                              ('credit_card', 'Thẻ TD'),
                            ],
                            selected: _type,
                            onChanged: (v) => setState(() => _type = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Overline('TÊN VÍ / TÀI KHOẢN'),
                        const SizedBox(height: 6),
                        FinoraTextField(
                          controller: _nameCtrl,
                          hint: 'Ví dụ: Ví MoMo, Techcombank...',
                          radius: 18,
                        ),
                        if (!isCredit) ...[
                          if (!isEditing) ...[
                            const SizedBox(height: 14),
                            const Overline('SỐ DƯ BAN ĐẦU'),
                            const SizedBox(height: 6),
                            FinoraTextField(
                              controller: _balanceCtrl,
                              hint: '0 ₫',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                DotSeparatorTextInputFormatter()
                              ],
                              radius: 18,
                            ),
                          ],
                          if (_type == 'bank') ...[
                            const SizedBox(height: 14),
                            const Overline('NGÂN HÀNG PHỔ BIẾN'),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 48,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  for (final bank in BankIconRegistry.brands)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _bankCodeCtrl.text = bank.code;
                                            if (_nameCtrl.text.isEmpty ||
                                                BankIconRegistry.brands.any(
                                                    (b) =>
                                                        b.code ==
                                                        _nameCtrl.text
                                                            .trim()
                                                            .toLowerCase())) {
                                              _nameCtrl.text = bank.shortName;
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: _bankCodeCtrl.text
                                                          .trim()
                                                          .toLowerCase() ==
                                                      bank.code
                                                  ? AppColors.primary
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: BankLogoView(
                                              bankCode: bank.code, size: 38),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Overline('SỐ TÀI KHOẢN'),
                            const SizedBox(height: 6),
                            FinoraTextField(
                              controller: _accountCtrl,
                              hint: 'Nhập số tài khoản ngân hàng...',
                              keyboardType: TextInputType.number,
                              radius: 18,
                            ),
                          ],
                        ] else ...[
                          if (!isEditing) ...[
                            const SizedBox(height: 14),
                            const Overline('HẠN MỨC THẺ TÍN DỤNG'),
                            const SizedBox(height: 6),
                            FinoraTextField(
                              controller: _limitCtrl,
                              hint: '0 ₫',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                DotSeparatorTextInputFormatter()
                              ],
                              radius: 18,
                            ),
                            const SizedBox(height: 14),
                            const Overline('DƯ NỢ HIỆN TẠI'),
                            const SizedBox(height: 6),
                            FinoraTextField(
                              controller: _debtCtrl,
                              hint: '0 ₫',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                DotSeparatorTextInputFormatter()
                              ],
                              radius: 18,
                            ),
                          ],
                          const SizedBox(height: 14),
                          const Overline('NGÂN HÀNG PHÁT HÀNH THẺ'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: BankIconRegistry.brands.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final bank = BankIconRegistry.brands[index];
                                final selected =
                                    _bankCodeCtrl.text.trim().toLowerCase() ==
                                        bank.code;
                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _bankCodeCtrl.text = bank.code;
                                      if (!isEditing &&
                                          _nameCtrl.text.trim().isEmpty) {
                                        _nameCtrl.text = bank.shortName;
                                      }
                                      if (_themeColor == '#3157D5') {
                                        _themeColor =
                                            '#${bank.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: selected
                                              ? bank.color
                                              : Colors.transparent,
                                          width: 2),
                                    ),
                                    child: BankLogoView(
                                        bankCode: bank.code, size: 38),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Overline('4 SỐ CUỐI CỦA THẺ'),
                          const SizedBox(height: 6),
                          FinoraTextField(
                            controller: _accountCtrl,
                            hint: 'Ví dụ: 8888',
                            keyboardType: TextInputType.number,
                            radius: 18,
                          ),
                          const SizedBox(height: 14),
                          const Overline('MÀU SẮC THẺ HIỂN THỊ'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (final opt in _colorOptions) ...[
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _themeColor = opt.$1);
                                  },
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
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        if (_themeColor == opt.$1)
                                          BoxShadow(
                                            color:
                                                opt.$2.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: PrimaryButton(
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
                expand: true,
                child: const Text('Lưu tài khoản / ví',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
