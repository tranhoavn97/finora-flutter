import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';

const Map<String, Color> _assetTypeColors = {
  'gold': Color(0xFFD97706),
  'stock': Color(0xFF2563EB),
  'crypto': Color(0xFF0891B2),
  'savings': AppColors.success,
  'simple_asset': AppColors.primary,
};

Color _assetTypeColor(String? key) =>
    _assetTypeColors[key] ?? AppColors.primary;

String _normalizedAssetTypeKey(String? key) {
  final normalized = (key ?? '').trim().toLowerCase();
  return _assetTypeColors.containsKey(normalized) ? normalized : 'simple_asset';
}

String _assetTypeEmoji(String? key) {
  switch (key) {
    case 'gold':
      return '🪙';
    case 'stock':
      return '📈';
    case 'crypto':
      return '⚡';
    case 'savings':
      return '🏦';
    default:
      return '💎';
  }
}

String _assetTypeLabel(String? key) {
  switch (key) {
    case 'gold':
      return 'Vàng & Kim loại quý';
    case 'stock':
      return 'Cổ phiếu & Chứng khoán';
    case 'crypto':
      return 'Crypto & Tài sản số';
    case 'savings':
      return 'Sổ tiết kiệm';
    default:
      return 'Tài sản đầu tư';
  }
}

/// Investment assets page — portfolio value, cost basis and P&L per holding.
class AssetScreen extends StatefulWidget {
  final String userId;
  const AssetScreen({super.key, required this.userId});

  @override
  State<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  StreamSubscription<String>? _eventsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MoreProvider>();
      provider.load(widget.userId);
      _eventsSub = provider.events.listen((msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      });
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _openAdd() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddAssetPage(userId: widget.userId),
    ));
  }

  void _openEdit(Asset asset) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddAssetPage(userId: widget.userId, asset: asset),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final provider = context.watch<MoreProvider>();
    final assets = provider.assets.where((a) => a.status == 'active').toList();

    final totalCost = assets.fold<int>(0, (s, a) => s + a.costBasis);
    final totalMarket = assets.fold<int>(0, (s, a) => s + a.marketValue);
    final totalProfit = totalMarket - totalCost;
    final profitPct = totalCost > 0 ? (totalProfit / totalCost) * 100.0 : 0.0;
    final profitColor = totalProfit >= 0 ? AppColors.success : AppColors.error;

    final allocation = <String, int>{};
    for (final a in assets) {
      final key = _normalizedAssetTypeKey(a.assetTypeKey);
      allocation[key] = (allocation[key] ?? 0) + a.marketValue;
    }
    final allocationTotal = allocation.values.fold<int>(0, (s, v) => s + v);

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Tài sản đầu tư',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _openAdd,
            icon: const Icon(Icons.add_rounded,
                color: AppColors.primary, size: 24),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E3A8A),
                      Color(0xFF2563EB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.32),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TỔNG GIÁ TRỊ DANH MỤC',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white70,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(
                            '${assets.length} tài sản',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatVND(totalMarket),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vốn đầu tư ban đầu',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatVND(totalCost),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Lợi nhuận tạm tính',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  totalProfit >= 0
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: totalProfit >= 0
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFFB7185),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${totalProfit >= 0 ? '+' : ''}${formatVND(totalProfit)} (${profitPct.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    color: totalProfit >= 0
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFFFB7185),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (allocationTotal > 0) ...[
                      const SizedBox(height: 12),
                      Divider(
                        color: Colors.white.withOpacity(0.18),
                        height: 1,
                      ),
                      const SizedBox(height: 10),
                      for (final entry in allocation.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _assetTypeColor(entry.key),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _assetTypeLabel(entry.key),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${(entry.value / allocationTotal * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: assets.isEmpty
                  ? Center(
                      child: EmptyState(
                        icon: Icons.trending_up_rounded,
                        title: 'Chưa có tài sản đầu tư',
                        subtitle:
                            'Hãy thêm các khoản đầu tư như cổ phiếu, crypto, vàng hoặc tiền gửi tiết kiệm.',
                        actionText: 'Thêm tài sản đầu tư',
                        onAction: _openAdd,
                      ),
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                      children: [
                        for (final asset in assets) ...[
                          _AssetRow(
                            key: ValueKey(asset.id),
                            asset: asset,
                            onEdit: () => _openEdit(asset),
                            onDelete: () async {
                              final confirm = await showConfirmDeleteDialog(
                                context: context,
                                title: 'Xóa tài sản?',
                                content:
                                    'Bạn có chắc chắn muốn xóa tài sản "${asset.name}" không?',
                              );
                              if (confirm && context.mounted) {
                                context
                                    .read<MoreProvider>()
                                    .deleteAsset(widget.userId, asset.id);
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  final Asset asset;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _AssetRow(
      {super.key,
      required this.asset,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;

    final profit = asset.marketValue - asset.costBasis;
    final pPct = asset.costBasis > 0 ? (profit / asset.costBasis) * 100.0 : 0.0;
    final profitColor = profit >= 0 ? AppColors.success : AppColors.error;
    final tint = _assetTypeColor(asset.assetTypeKey);

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconBadge(
            emoji: _assetTypeEmoji(asset.assetTypeKey),
            tint: tint,
            size: 42,
            radius: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'SL: ${asset.quantity} ${asset.unit ?? ''} • Vốn: ${formatVND(asset.costBasis)}',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatVND(asset.marketValue),
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${profit >= 0 ? '+' : ''}${formatVND(profit)} (${pPct.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: profitColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn',
            icon: Icon(Icons.more_vert_rounded, color: c.textSecondary),
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Chỉnh sửa'),
                      contentPadding: EdgeInsets.zero)),
              PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      title:
                          Text('Xóa', style: TextStyle(color: AppColors.error)),
                      contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
    );
  }
}

class AddAssetPage extends StatefulWidget {
  final String userId;
  final Asset? asset;
  const AddAssetPage({super.key, required this.userId, this.asset});

  @override
  State<AddAssetPage> createState() => _AddAssetPageState();
}

class _AddAssetPageState extends State<AddAssetPage> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: 'lần');
  final _buyPriceController = TextEditingController();
  final _currentPriceController = TextEditingController();
  String _assetTypeKey = 'simple_asset';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    if (asset != null) {
      _nameController.text = asset.name;
      _qtyController.text = asset.quantity.toString();
      _unitController.text = asset.unit ?? 'lần';
      _buyPriceController.text = asset.buyPrice.toString();
      _currentPriceController.text = asset.currentPrice.toString();
      _assetTypeKey = asset.assetTypeKey ?? 'simple_asset';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _buyPriceController.dispose();
    _currentPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final qty =
          double.tryParse(_qtyController.text.trim().replaceAll(',', '.')) ??
              1.0;
      final buyPrice = int.tryParse(
              _buyPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
      final currentPrice = int.tryParse(
              _currentPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          buyPrice;
      final cost = (qty * buyPrice).round();
      final market = (qty * currentPrice).round();
      final now = DateTime.now().millisecondsSinceEpoch;
      final asset = Asset(
        id: widget.asset?.id ?? '',
        userId: widget.userId,
        name: name,
        type: 'investment',
        assetTypeKey: _assetTypeKey,
        investmentSubtype: _assetTypeKey,
        quantity: qty,
        unit: _unitController.text.trim().isEmpty
            ? 'lần'
            : _unitController.text.trim(),
        buyPrice: buyPrice,
        purchasePrice: buyPrice,
        costBasis: cost,
        currentPrice: currentPrice,
        marketValue: market,
        status: widget.asset?.status ?? 'active',
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassTopBar(
        title: widget.asset == null ? 'Thêm tài sản đầu tư' : 'Sửa tài sản',
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
                        const Overline('LOẠI TÀI SẢN'),
                        const SizedBox(height: 6),
                        SegmentedControl(
                          options: const [
                            ('gold', 'Vàng'),
                            ('stock', 'Cổ phiếu'),
                            ('crypto', 'Crypto'),
                            ('savings', 'Tiết kiệm'),
                          ],
                          selected: _assetTypeKey,
                          onChanged: (v) => setState(() => _assetTypeKey = v),
                        ),
                        const SizedBox(height: 14),
                        const Overline('TÊN TÀI SẢN ĐẦU TƯ'),
                        const SizedBox(height: 6),
                        FinoraTextField(
                          controller: _nameController,
                          hint: 'Ví dụ: Bitcoin, Vàng SJC, Apple Inc...',
                          radius: 18,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Overline('SỐ LƯỢNG'),
                                  const SizedBox(height: 6),
                                  FinoraTextField(
                                    controller: _qtyController,
                                    hint: '1.0',
                                    keyboardType: TextInputType.number,
                                    radius: 18,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Overline('ĐƠN VỊ TÍNH'),
                                  const SizedBox(height: 6),
                                  FinoraTextField(
                                    controller: _unitController,
                                    hint: 'Chỉ, cổ phiếu...',
                                    radius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Overline('GIÁ MUA VÀO'),
                                  const SizedBox(height: 6),
                                  FinoraTextField(
                                    controller: _buyPriceController,
                                    hint: '0 ₫',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      DotSeparatorTextInputFormatter()
                                    ],
                                    radius: 18,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Overline('GIÁ THỊ TRƯỜNG'),
                                  const SizedBox(height: 6),
                                  FinoraTextField(
                                    controller: _currentPriceController,
                                    hint: '0 ₫',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      DotSeparatorTextInputFormatter()
                                    ],
                                    radius: 18,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: PrimaryButton(
                expand: true,
                onPressed: _isSaving ? null : _submit,
                isLoading: _isSaving,
                child: Text(
                    widget.asset == null ? 'Lưu tài sản' : 'Lưu thay đổi',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
