import 'dart:ui';

import '../../core/widgets/finora_modal_scope.dart';
import '../../core/widgets/finora_notice.dart';
import '../../core/widgets/finora_transaction_success_modal.dart';
import '../../core/widgets/fresh_design.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../data/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';

/// Comprehensive Asset creation & editing page styled like AddTransactionPage
/// ("modal ghi chép") with circular subtype badges, live hero valuation card,
/// Bento input groups, and celebratory receipt modal on save/update.
class AddAssetPage extends StatefulWidget {
  final String userId;
  final Asset? asset;
  const AddAssetPage({super.key, required this.userId, this.asset});

  @override
  State<AddAssetPage> createState() => _AddAssetPageState();
}

class _AddAssetPageState extends State<AddAssetPage> {
  String _subtype =
      'gold'; // 'gold', 'real_estate', 'stock', 'crypto', 'savings', 'hui_phuong', 'simple_asset'
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: 'chỉ');
  final _buyPriceController = TextEditingController();
  final _currentPriceController = TextEditingController();

  // Savings specific
  final _interestRateController = TextEditingController(text: '6.5');
  final _termMonthsController = TextEditingController(text: '12');

  // Hui / Phuong specific
  final _periodAmountController = TextEditingController(text: '2.000.000');
  final _totalPeriodsController = TextEditingController(text: '12');
  final _currentPeriodController = TextEditingController(text: '1');
  final _contributedAmountController = TextEditingController(text: '2.000.000');
  final _receivedAmountController = TextEditingController(text: '0');

  bool _isSaving = false;

  static const List<
      ({
        String key,
        String label,
        IconData icon,
        Color color,
        Color secondaryColor
      })> _subtypeDefs = [
    (
      key: 'gold',
      label: 'Vàng',
      icon: Icons.monetization_on_rounded,
      color: Color(0xFFD97706),
      secondaryColor: Color(0xFFF59E0B),
    ),
    (
      key: 'real_estate',
      label: 'BĐS',
      icon: Icons.home_work_rounded,
      color: Color(0xFF059669),
      secondaryColor: Color(0xFF10B981),
    ),
    (
      key: 'stock',
      label: 'Cổ phiếu',
      icon: Icons.candlestick_chart_rounded,
      color: Color(0xFF2563EB),
      secondaryColor: Color(0xFF38BDF8),
    ),
    (
      key: 'crypto',
      label: 'Crypto',
      icon: Icons.currency_bitcoin_rounded,
      color: Color(0xFF0284C7),
      secondaryColor: Color(0xFF06B6D4),
    ),
    (
      key: 'savings',
      label: 'Sổ tiết kiệm',
      icon: Icons.savings_rounded,
      color: Color(0xFF0D9488),
      secondaryColor: Color(0xFF14B8A6),
    ),
    (
      key: 'hui_phuong',
      label: 'Hụi/Phường',
      icon: Icons.groups_rounded,
      color: Color(0xFFEA580C),
      secondaryColor: Color(0xFFF97316),
    ),
    (
      key: 'simple_asset',
      label: 'Khác',
      icon: Icons.diamond_rounded,
      color: Color(0xFF0F6E56),
      secondaryColor: Color(0xFF10B981),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    if (a != null) {
      final rawKey = (a.investmentSubtype ?? a.assetTypeKey ?? a.type).trim();
      _subtype = _subtypeDefs.any((d) => d.key == rawKey) ? rawKey : 'gold';
      _nameController.text = a.name;
      _qtyController.text = a.quantity.toString();
      _unitController.text = a.unit ?? '';
      final initialBuy = a.buyPrice > 0 ? a.buyPrice : a.costBasis;
      final initialCurr = a.currentPrice > 0 ? a.currentPrice : a.marketValue;
      _buyPriceController.text = initialBuy > 0
          ? DotSeparatorTextInputFormatter.formatDigits(initialBuy.toString())
          : '';
      _currentPriceController.text = initialCurr > 0
          ? DotSeparatorTextInputFormatter.formatDigits(initialCurr.toString())
          : '';

      _interestRateController.text = a.interestRate.toString();
      _termMonthsController.text = a.termMonths.toString();

      _periodAmountController.text =
          DotSeparatorTextInputFormatter.formatDigits(
              a.periodAmount.toString());
      _totalPeriodsController.text = a.totalPeriods.toString();
      _currentPeriodController.text = a.currentPeriod.toString();
      _contributedAmountController.text =
          DotSeparatorTextInputFormatter.formatDigits(
              a.contributedAmount.toString());
      _receivedAmountController.text =
          DotSeparatorTextInputFormatter.formatDigits(
              a.receivedAmount.toString());
    } else {
      _applySubtypeDefaults(_subtype);
    }

    for (final c in [
      _nameController,
      _qtyController,
      _buyPriceController,
      _currentPriceController,
      _interestRateController,
      _termMonthsController,
      _periodAmountController,
      _totalPeriodsController,
      _currentPeriodController,
      _contributedAmountController,
      _receivedAmountController,
    ]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _applySubtypeDefaults(String type) {
    switch (type) {
      case 'gold':
        _unitController.text = 'Chỉ';
        if (_nameController.text.isEmpty) {
          _nameController.text = 'Vàng SJC 9999';
        }
        break;
      case 'real_estate':
        _unitController.text = 'M2';
        if (_nameController.text.isEmpty) {
          _nameController.text = 'Bất động sản đất nền';
        }
        break;
      case 'stock':
        _unitController.text = 'Cổ phiếu';
        if (_nameController.text.isEmpty) _nameController.text = 'Cổ phiếu FPT';
        break;
      case 'crypto':
        _unitController.text = 'Coin';
        if (_nameController.text.isEmpty) {
          _nameController.text = 'Bitcoin (BTC)';
        }
        break;
      case 'savings':
        _unitController.text = 'Sổ';
        if (_nameController.text.isEmpty) {
          _nameController.text = 'Tiết kiệm Vietcombank';
        }
        break;
      case 'hui_phuong':
        _unitController.text = 'Dây';
        if (_nameController.text.isEmpty) {
          _nameController.text = 'Dây Hụi 2 Triệu/Tháng';
        }
        break;
      default:
        _unitController.text = 'Món';
        break;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _qtyController,
      _buyPriceController,
      _currentPriceController,
      _interestRateController,
      _termMonthsController,
      _periodAmountController,
      _totalPeriodsController,
      _currentPeriodController,
      _contributedAmountController,
      _receivedAmountController,
    ]) {
      c.removeListener(_onFieldChanged);
    }
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _buyPriceController.dispose();
    _currentPriceController.dispose();
    _interestRateController.dispose();
    _termMonthsController.dispose();
    _periodAmountController.dispose();
    _totalPeriodsController.dispose();
    _currentPeriodController.dispose();
    _contributedAmountController.dispose();
    _receivedAmountController.dispose();
    super.dispose();
  }

  ({int costBasis, int marketValue}) _computeLiveValuation() {
    final qty =
        double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 1.0;
    final buyPrice = int.tryParse(
            _buyPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    final currentPrice = int.tryParse(
            _currentPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        buyPrice;

    int costBasis = (qty * buyPrice).round();
    int marketValue = (qty * currentPrice).round();

    if (_subtype == 'hui_phuong') {
      final periodAmount = int.tryParse(
              _periodAmountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
      final currentPeriod = int.tryParse(_currentPeriodController.text
              .replaceAll(RegExp(r'[^0-9]'), '')) ??
          1;
      final contributedAmount = int.tryParse(_contributedAmountController.text
              .replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
      final receivedAmount = int.tryParse(_receivedAmountController.text
              .replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
      costBasis = contributedAmount > 0
          ? contributedAmount
          : (currentPeriod * periodAmount);
      marketValue = receivedAmount > 0 ? receivedAmount : costBasis;
    } else if (_subtype == 'savings') {
      if (costBasis <= 0) costBasis = buyPrice;
      final interestRate =
          double.tryParse(_interestRateController.text.replaceAll(',', '.')) ??
              0.0;
      final termMonths = int.tryParse(
              _termMonthsController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          12;
      final months = termMonths > 0 ? termMonths : 1;
      final expectedInterest =
          (costBasis * (interestRate / 100.0) * (months / 12.0)).round();
      marketValue = costBasis + expectedInterest;
    }
    return (costBasis: costBasis, marketValue: marketValue);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên tài sản')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final qty =
          double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 1.0;
      final buyPrice = int.tryParse(
              _buyPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
      final currentPrice = int.tryParse(
              _currentPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          buyPrice;

      final valuation = _computeLiveValuation();
      final costBasis = valuation.costBasis;
      final marketValue = valuation.marketValue;

      final interestRate =
          double.tryParse(_interestRateController.text.replaceAll(',', '.')) ??
              0.0;
      final termMonths = int.tryParse(
              _termMonthsController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          12;

      final periodAmount = int.tryParse(
              _periodAmountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
      final totalPeriods = int.tryParse(
              _totalPeriodsController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          12;
      final currentPeriod = int.tryParse(_currentPeriodController.text
              .replaceAll(RegExp(r'[^0-9]'), '')) ??
          1;
      final receivedAmount = int.tryParse(_receivedAmountController.text
              .replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;

      final now = DateTime.now().millisecondsSinceEpoch;
      final asset = Asset(
        id: widget.asset?.id ?? '',
        userId: widget.userId,
        name: name,
        type: 'investment',
        assetTypeKey: _subtype,
        investmentSubtype: _subtype,
        quantity: qty,
        unit: _unitController.text.trim().isEmpty
            ? 'lần'
            : _unitController.text.trim(),
        buyPrice: buyPrice,
        purchasePrice: buyPrice,
        costBasis: costBasis,
        currentPrice: currentPrice,
        marketValue: marketValue,
        profitLoss: marketValue - costBasis,
        profitLossPercent: costBasis > 0
            ? ((marketValue - costBasis) / costBasis) * 100.0
            : 0.0,
        status: widget.asset?.status ?? 'active',
        interestRate: interestRate,
        termMonths: termMonths,
        periodAmount: periodAmount,
        totalPeriods: totalPeriods,
        currentPeriod: currentPeriod,
        contributedAmount: costBasis,
        receivedAmount: receivedAmount,
        remainingContribution: (totalPeriods - currentPeriod) * periodAmount,
        netPosition: receivedAmount - costBasis,
        createdAt: widget.asset?.createdAt ?? now,
        updatedAt: now,
      );

      final isEditing = widget.asset != null;
      if (!isEditing) {
        await context.read<MoreProvider>().addAsset(widget.userId, asset);
      } else {
        await context
            .read<MoreProvider>()
            .updateAsset(widget.userId, widget.asset!.id, asset);
      }

      if (!mounted) return;
      final subDef = _subtypeDefs.firstWhere(
        (d) => d.key == _subtype,
        orElse: () => _subtypeDefs.first,
      );
      final receiptTx = TransactionModel(
        id: asset.id.isNotEmpty ? asset.id : 'asset_$now',
        userId: widget.userId,
        amount: marketValue > 0 ? marketValue : costBasis,
        type: 'investment',
        date: now,
        note: isEditing ? 'Đã cập nhật: $name' : 'Ghi nhận mới: $name',
        categoryId: _subtype,
        categoryName: '${subDef.label} • $name',
        categoryIcon: 'trending_up',
        walletName: 'Danh mục đầu tư',
        creatorTag: 'Đầu tư',
      );
      await FinoraTransactionSuccessModal.show(
        context,
        transaction: receiptTx,
        walletName: 'Danh mục ${subDef.label}',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addQuickPrice(int delta) {
    HapticFeedback.selectionClick();
    final targetCtrl = _subtype == 'hui_phuong'
        ? _periodAmountController
        : (_currentPriceController.text.isNotEmpty && _subtype != 'savings'
            ? _currentPriceController
            : _buyPriceController);
    final current =
        int.tryParse(targetCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final next = (current + delta).clamp(0, 999000000000);
    targetCtrl.text = DotSeparatorTextInputFormatter.formatDigits(next.toString());
    if (_subtype != 'savings' &&
        _subtype != 'hui_phuong' &&
        _currentPriceController.text.isEmpty) {
      _currentPriceController.text = targetCtrl.text;
    }
    setState(() {});
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final isEditing = widget.asset != null;
    final subDef = _subtypeDefs.firstWhere(
      (d) => d.key == _subtype,
      orElse: () => _subtypeDefs.first,
    );
    final valuation = _computeLiveValuation();
    final diff = valuation.marketValue - valuation.costBasis;
    final diffPct = valuation.costBasis > 0
        ? (diff / valuation.costBasis) * 100.0
        : 0.0;

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: isEditing ? 'Cập nhật tài sản' : 'Thêm tài sản mới',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              14,
              GlassScaffold.topInset(context, 10),
              14,
              MediaQuery.paddingOf(context).bottom + 96,
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Live Hero Valuation Card (like AddTransactionPage amount hero)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          subDef.color.withValues(alpha: isDark ? 0.30 : 0.14),
                          subDef.secondaryColor
                              .withValues(alpha: isDark ? 0.16 : 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: subDef.color
                            .withValues(alpha: isDark ? 0.45 : 0.28),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: subDef.color
                              .withValues(alpha: isDark ? 0.18 : 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    subDef.color,
                                    subDef.secondaryColor,
                                  ],
                                ),
                              ),
                              child: Icon(
                                subDef.icon,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GIÁ TRỊ ĐỊNH GIÁ (${subDef.label.toUpperCase()})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatVND(valuation.marketValue > 0
                                ? valuation.marketValue
                                : valuation.costBasis),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: primaryTextColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'Giá vốn: ${formatVND(valuation.costBasis)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: (diff >= 0
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFE11D48))
                                    .withValues(alpha: isDark ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${diff >= 0 ? '+' : ''}${formatVND(diff)} (${diff >= 0 ? '+' : ''}${diffPct.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: diff >= 0
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFE11D48),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Quick amount chips like AddTransactionPage
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (final chip in const [
                                ('+1tr', 1000000),
                                ('+5tr', 5000000),
                                ('+10tr', 10000000),
                                ('+50tr', 50000000),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    onTap: () => _addQuickPrice(chip.$2),
                                    borderRadius: BorderRadius.circular(100),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4.5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.08)
                                            : Colors.white
                                                .withValues(alpha: 0.85),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        border: Border.all(
                                          color: subDef.color
                                              .withValues(alpha: 0.28),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        chip.$1,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: subDef.color,
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

                  const SizedBox(height: 16),

                  // 2. Circular Subtype Selector ("icon đầu tư để dạng tròn đẹp hơn")
                  Text(
                    'PHÂN LOẠI TÀI SẢN ĐẦU TƯ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: secondaryTextColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _subtypeDefs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = _subtypeDefs[index];
                        final selected = _subtype == item.key;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _subtype = item.key;
                              _applySubtypeDefaults(item.key);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 68,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? item.color
                                      .withValues(alpha: isDark ? 0.22 : 0.12)
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? item.color
                                    : (isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0)),
                                width: selected ? 1.5 : 0.9,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: selected
                                          ? [item.color, item.secondaryColor]
                                          : [
                                              item.color.withValues(alpha: 0.18),
                                              item.secondaryColor
                                                  .withValues(alpha: 0.12),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: item.color
                                                  .withValues(alpha: 0.32),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 18,
                                    color:
                                        selected ? Colors.white : item.color,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: selected
                                          ? (isDark
                                              ? Colors.white
                                              : item.color)
                                          : secondaryTextColor,
                                    ),
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

                  // 3. Bento Form Container (matching AddTransactionPage card style)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.22 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(
                            'Tên tài sản / Hạng mục', primaryTextColor),
                        _buildInput(_nameController,
                            'Ví dụ: Vàng PNJ 9999, Sổ VCB...', isDark,
                            prefixIcon: Icons.label_important_outline_rounded,
                            accentColor: subDef.color),
                        const SizedBox(height: 14),
                        if (_subtype == 'hui_phuong') ...[
                          _fieldLabel(
                              'Số tiền mỗi kỳ (VND)', primaryTextColor),
                          _buildInput(
                              _periodAmountController, '2.000.000', isDark,
                              isCurrency: true,
                              prefixIcon: Icons.payments_outlined,
                              accentColor: subDef.color),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel(
                                        'Tổng số kỳ', primaryTextColor),
                                    _buildInput(
                                        _totalPeriodsController, '12', isDark,
                                        isNumber: true,
                                        prefixIcon: Icons.repeat_rounded,
                                        accentColor: subDef.color),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel(
                                        'Kỳ hiện tại', primaryTextColor),
                                    _buildInput(
                                        _currentPeriodController, '1', isDark,
                                        isNumber: true,
                                        prefixIcon: Icons.timelapse_rounded,
                                        accentColor: subDef.color),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel(
                                        'Đã đóng (VND)', primaryTextColor),
                                    _buildInput(_contributedAmountController,
                                        '0', isDark,
                                        isCurrency: true,
                                        prefixIcon: Icons.upload_rounded,
                                        accentColor: subDef.color),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel(
                                        'Đã hốt/lĩnh (VND)', primaryTextColor),
                                    _buildInput(
                                        _receivedAmountController, '0', isDark,
                                        isCurrency: true,
                                        prefixIcon: Icons.download_rounded,
                                        accentColor: subDef.color),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else if (_subtype == 'savings') ...[
                          _fieldLabel(
                              'Số tiền gửi gốc (VND)', primaryTextColor),
                          _buildInput(
                              _buyPriceController, '100.000.000', isDark,
                              isCurrency: true,
                              prefixIcon: Icons.account_balance_wallet_outlined,
                              accentColor: subDef.color),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel(
                                        'Lãi suất % / năm', primaryTextColor),
                                    _buildInput(
                                        _interestRateController, '6.5', isDark,
                                        isNumber: true,
                                        prefixIcon: Icons.percent_rounded,
                                        accentColor: subDef.color),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel(
                                        'Kỳ hạn (tháng)', primaryTextColor),
                                    _buildInput(
                                        _termMonthsController, '12', isDark,
                                        isNumber: true,
                                        prefixIcon:
                                            Icons.calendar_month_rounded,
                                        accentColor: subDef.color),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel('Số lượng', primaryTextColor),
                                    _buildInput(_qtyController, '1', isDark,
                                        isNumber: true,
                                        prefixIcon: Icons.numbers_rounded,
                                        accentColor: subDef.color),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel(
                                        'Đơn vị tính', primaryTextColor),
                                    _buildInput(_unitController,
                                        'Chỉ, m2, cp...', isDark,
                                        prefixIcon: Icons.straighten_rounded,
                                        accentColor: subDef.color),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('Giá mua vào / Giá vốn đơn vị (VND)',
                              primaryTextColor),
                          _buildInput(
                              _buyPriceController, 'Giá lúc mua', isDark,
                              isCurrency: true,
                              prefixIcon: Icons.shopping_bag_outlined,
                              accentColor: subDef.color),
                          const SizedBox(height: 14),
                          _fieldLabel('Giá thị trường hiện tại đơn vị (VND)',
                              primaryTextColor),
                          _buildInput(
                              _currentPriceController, 'Giá hôm nay', isDark,
                              isCurrency: true,
                              prefixIcon: Icons.trending_up_rounded,
                              accentColor: subDef.color),
                        ],
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
              child: _buildFloatingSaveButton(isDark, isEditing, subDef.color),
            ),
          ],
        ),
    );
  }

  Widget _buildFloatingSaveButton(
      bool isDark, bool isEditing, Color accentColor) {
    final pageBg = isDark ? const Color(0xFF0B1120) : FreshColors.background;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
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
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 4,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 19),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'CẬP NHẬT TÀI SẢN' : 'LƯU TÀI SẢN MỚI',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
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

  Widget _fieldLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint,
    bool isDark, {
    bool isNumber = false,
    bool isCurrency = false,
    IconData? prefixIcon,
    Color? accentColor,
  }) {
    final formatters = <TextInputFormatter>[
      if (isCurrency)
        const DotSeparatorTextInputFormatter()
      else if (!isNumber)
        const FirstLetterUpperCaseFormatter(),
    ];
    final activeColor = accentColor ?? AppColors.primary;
    return TextField(
      controller: controller,
      textCapitalization: (!isNumber && !isCurrency)
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      inputFormatters: formatters,
      keyboardType: isCurrency
          ? TextInputType.number
          : (isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: activeColor)
            : null,
        suffixText: isCurrency ? '₫' : null,
        suffixStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : FreshColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: activeColor, width: 1.5),
        ),
      ),
    );
  }
}
