import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';

/// Comprehensive Asset creation & editing page matching Web form options.
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

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    if (a != null) {
      _subtype = a.investmentSubtype ?? a.assetTypeKey ?? 'gold';
      _nameController.text = a.name;
      _qtyController.text = a.quantity.toString();
      _unitController.text = a.unit ?? '';
      _buyPriceController.text = a.buyPrice > 0
          ? DotSeparatorTextInputFormatter.formatDigits(a.buyPrice.toString())
          : '';
      _currentPriceController.text = a.currentPrice > 0
          ? DotSeparatorTextInputFormatter.formatDigits(
              a.currentPrice.toString())
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
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

      int costBasis = (qty * buyPrice).round();
      int marketValue = (qty * currentPrice).round();

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
      final contributedAmount = int.tryParse(_contributedAmountController.text
              .replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
      final receivedAmount = int.tryParse(_receivedAmountController.text
              .replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;

      // Special cost and market adjustments for Hui and Savings
      if (_subtype == 'hui_phuong') {
        costBasis = contributedAmount > 0
            ? contributedAmount
            : (currentPeriod * periodAmount);
        marketValue = receivedAmount > 0 ? receivedAmount : costBasis;
      } else if (_subtype == 'savings') {
        if (costBasis <= 0) costBasis = buyPrice;
        // Calculated expected maturity value
        final months = termMonths > 0 ? termMonths : 1;
        final expectedInterest =
            (costBasis * (interestRate / 100.0) * (months / 12.0)).round();
        marketValue = costBasis + expectedInterest;
      }

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

      if (widget.asset == null) {
        await context.read<MoreProvider>().addAsset(widget.userId, asset);
      } else {
        await context
            .read<MoreProvider>()
            .updateAsset(widget.userId, widget.asset!.id, asset);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.asset == null ? 'Thêm tài sản mới' : 'Cập nhật tài sản',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Asset Subtype Selector
            Text(
              'CHỌN LOẠI TÀI SẢN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: secondaryTextColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                const keys = [
                  'gold',
                  'real_estate',
                  'stock',
                  'crypto',
                  'savings',
                  'hui_phuong',
                  'simple_asset'
                ];
                final rawIdx = keys.indexOf(_subtype);
                final safeIdx = rawIdx < 0 ? 0 : rawIdx;
                return FinoraScrollableSegmentedTabs(
                  height: 42,
                  labels: const [
                    'Vàng',
                    'BĐS',
                    'Cổ phiếu',
                    'Crypto',
                    'Sổ tiết kiệm',
                    'Hụi/Phường',
                    'Khác'
                  ],
                  icons: const ['🪙', '🏡', '📈', '⚡', '🏦', '🤝', '💎'],
                  selectedIndex: safeIdx,
                  colors: const [
                    Color(0xFFD97706), // Vàng - Gold Amber
                    Color(0xFF059669), // BĐS - Emerald
                    Color(0xFF2563EB), // Cổ phiếu - Cobalt Blue
                    Color(0xFF7C3AED), // Crypto - Violet
                    Color(0xFF0D9488), // Sổ tiết kiệm - Teal/Sapphire
                    Color(0xFFEA580C), // Hụi/Phường - Orange
                    Color(0xFF0F6E56), // Khác - Emerald Mint
                  ],
                  onChanged: (index) {
                    final key = keys[index];
                    setState(() {
                      _subtype = key;
                      _applySubtypeDefaults(key);
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 18),

            // Form inputs container
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name input
                  _fieldLabel('Tên tài sản / Hạng mục', primaryTextColor),
                  _buildInput(_nameController,
                      'Ví dụ: Vàng PNJ 9999, Sổ VCB...', isDark),

                  const SizedBox(height: 14),

                  // Dynamic subtype fields
                  if (_subtype == 'hui_phuong') ...[
                    _fieldLabel('Số tiền mỗi kỳ (VND)', primaryTextColor),
                    _buildInput(_periodAmountController, '2.000.000', isDark,
                        isCurrency: true),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Tổng số kỳ', primaryTextColor),
                              _buildInput(_totalPeriodsController, '12', isDark,
                                  isNumber: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Kỳ hiện tại', primaryTextColor),
                              _buildInput(_currentPeriodController, '1', isDark,
                                  isNumber: true),
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
                              _fieldLabel('Đã đóng (VND)', primaryTextColor),
                              _buildInput(
                                  _contributedAmountController, '0', isDark,
                                  isCurrency: true),
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
                                  isCurrency: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else if (_subtype == 'savings') ...[
                    _fieldLabel('Số tiền gửi gốc (VND)', primaryTextColor),
                    _buildInput(_buyPriceController, '100.000.000', isDark,
                        isCurrency: true),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Lãi suất % / năm', primaryTextColor),
                              _buildInput(
                                  _interestRateController, '6.5', isDark,
                                  isNumber: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Kỳ hạn (tháng)', primaryTextColor),
                              _buildInput(_termMonthsController, '12', isDark,
                                  isNumber: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Standard quantified / simple asset
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Số lượng', primaryTextColor),
                              _buildInput(_qtyController, '1', isDark,
                                  isNumber: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Đơn vị tính', primaryTextColor),
                              _buildInput(
                                  _unitController, 'Chỉ, m2, cp...', isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel(
                        'Giá mua vào / Giá vốn đơn vị (VND)', primaryTextColor),
                    _buildInput(_buyPriceController, 'Giá lúc mua', isDark,
                        isCurrency: true),
                    const SizedBox(height: 14),
                    _fieldLabel('Giá thị trường hiện tại đơn vị (VND)',
                        primaryTextColor),
                    _buildInput(_currentPriceController, 'Giá hôm nay', isDark,
                        isCurrency: true),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                elevation: 4,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      widget.asset == null
                          ? 'LƯU TÀI SẢN MỚI'
                          : 'CẬP NHẬT TÀI SẢN',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
          ],
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
          fontSize: 12.5,
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
  }) {
    final formatters = <TextInputFormatter>[
      if (isCurrency)
        const DotSeparatorTextInputFormatter()
      else if (!isNumber)
        const FirstLetterUpperCaseFormatter(),
    ];
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
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
