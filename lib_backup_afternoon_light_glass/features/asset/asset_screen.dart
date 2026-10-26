import 'dart:async';

import 'package:flutter/material.dart';
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
  'crypto': Color(0xFF7C3AED),
  'savings': AppColors.success,
  'simple_asset': AppColors.accent,
};

Color _assetTypeColor(String? key) =>
    _assetTypeColors[key] ?? AppColors.success;

String _assetTypeEmoji(String? key) {
  switch (key) {
    case 'gold':
      return '🪙';
    case 'stock':
      return '📈';
    case 'crypto':
      return '🪙';
    case 'savings':
      return '🏦';
    default:
      return '💎';
  }
}

String _assetTypeLabel(String? key) {
  switch (key) {
    case 'gold':
      return 'Vàng';
    case 'stock':
      return 'Cổ phiếu';
    case 'crypto':
      return 'Crypto';
    case 'savings':
      return 'Tiết kiệm';
    default:
      return 'Tài sản cơ bản';
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
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddAssetPage(userId: widget.userId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final provider = context.watch<MoreProvider>();
    final assets =
        provider.assets.where((a) => a.status == 'active').toList();

    final totalCost = assets.fold<int>(0, (s, a) => s + a.costBasis);
    final totalMarket = assets.fold<int>(0, (s, a) => s + a.marketValue);
    final totalProfit = totalMarket - totalCost;
    final profitPct =
        totalCost > 0 ? (totalProfit / totalCost) * 100.0 : 0.0;
    final profitColor =
        totalProfit >= 0 ? AppColors.success : AppColors.error;

    // Allocation by assetTypeKey for the legend.
    final allocation = <String, int>{};
    for (final a in assets) {
      final key = a.assetTypeKey ?? 'simple_asset';
      allocation[key] = (allocation[key] ?? 0) + a.marketValue;
    }
    final allocationTotal =
        allocation.values.fold<int>(0, (s, v) => s + v);

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Tài sản đầu tư',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _openAdd,
            icon: const Icon(Icons.add, color: AppColors.accent),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
            child: GlassCard(
              highlighted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GIÁ TRỊ DANH MỤC HIỆN TẠI',
                      style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Text(formatVND(totalMarket),
                      style: AppTypography.largeTitle.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tổng vốn bỏ ra',
                              style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
                          Text(formatVND(totalCost),
                              style: AppTypography.body.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Tổng lãi / lỗ',
                              style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  totalProfit >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: profitColor,
                                  size: 16),
                              const SizedBox(width: 4),
                              Text(
                                  '${totalProfit >= 0 ? '+' : ''}${formatVND(totalProfit)} (${profitPct.toStringAsFixed(2)}%)',
                                  style: AppTypography.body.copyWith(
                                      color: profitColor,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (allocationTotal > 0) ...[
                    const SizedBox(height: 14),
                    Divider(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08), height: 1),
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
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _assetTypeColor(entry.key),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_assetTypeLabel(entry.key),
                                    style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
                              ],
                            ),
                            Text(
                                '${(entry.value / allocationTotal * 100).toStringAsFixed(1)}%',
                                style: AppTypography.caption2.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: assets.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.trending_up,
                      title: 'Chưa có tài sản đầu tư',
                      subtitle:
                          'Hãy thêm các khoản đầu tư như cổ phiếu, crypto, vàng hoặc tiền tiết kiệm để theo dõi.',
                      actionText: '+ Thêm tài sản đầu tư',
                      onAction: _openAdd,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 24),
                    children: [
                      Text('DANH SÁCH TÀI SẢN ĐANG NẮM GIỮ',
                          style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 12),
                      for (final asset in assets) ...[
                        _AssetRow(
                          key: ValueKey(asset.id),
                          asset: asset,
                          onDelete: () async {
                            final confirm = await showConfirmDeleteDialog(
                              context: context,
                              title: 'Xóa tài sản?',
                              content: 'Bạn có chắc chắn muốn xóa tài sản "${asset.name}" không?',
                            );
                            if (confirm && context.mounted) {
                              context
                                  .read<MoreProvider>()
                                  .deleteAsset(widget.userId, asset.id);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  final Asset asset;
  final VoidCallback onDelete;
  const _AssetRow({super.key, required this.asset, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final profit = asset.marketValue - asset.costBasis;
    final pPct =
        asset.costBasis > 0 ? (profit / asset.costBasis) * 100.0 : 0.0;
    final profitColor = profit >= 0 ? AppColors.success : AppColors.error;
    final tint = _assetTypeColor(asset.assetTypeKey);

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconBadge(emoji: _assetTypeEmoji(asset.assetTypeKey), tint: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.name,
                    style: AppTypography.body.copyWith(
                        color: primaryTextColor, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                    'SL: ${asset.quantity} ${asset.unit ?? ''} • Vốn: ${formatVND(asset.costBasis)}',
                    style: AppTypography.caption2.copyWith(color: secondaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatVND(asset.marketValue),
                  style: AppTypography.body.copyWith(
                      color: primaryTextColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                  '${profit >= 0 ? '+' : ''}${formatVND(profit)} (${pPct.toStringAsFixed(1)}%)',
                  style: AppTypography.caption2.copyWith(
                      color: profitColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }
}

/// Full-screen form to add an investment asset.
class AddAssetPage extends StatefulWidget {
  final String userId;
  const AddAssetPage({super.key, required this.userId});

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
      final qty = double.tryParse(_qtyController.text.trim().replaceAll(',', '.')) ?? 1.0;
      final buyPrice = int.tryParse(_buyPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final currentPrice =
          int.tryParse(_currentPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? buyPrice;
      final cost = (qty * buyPrice).round();
      final market = (qty * currentPrice).round();
      final now = DateTime.now().millisecondsSinceEpoch;
      final asset = Asset(
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
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );
      await context.read<MoreProvider>().addAsset(widget.userId, asset);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Thêm tài sản đầu tư',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
              children: [
                Text('Loại tài sản',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
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
                const SizedBox(height: AppSpacing.md),
                Text('Tên tài sản đầu tư',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                GlassTextField(
                  controller: _nameController,
                  hint: 'Ví dụ: Bitcoin, Vàng SJC, Apple Inc...',
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Số lượng',
                              style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          GlassTextField(
                            controller: _qtyController,
                            hint: '1.0',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đơn vị tính',
                              style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          GlassTextField(
                            controller: _unitController,
                            hint: 'Chỉ, cổ phiếu, coin...',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Giá mua trung bình',
                              style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          GlassTextField(
                            controller: _buyPriceController,
                            hint: '0 ₫',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Giá thị trường hiện tại',
                              style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          GlassTextField(
                            controller: _currentPriceController,
                            hint: '0 ₫',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: PrimaryButton(
                expand: true,
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lưu tài sản',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
