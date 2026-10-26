import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';
import '../../state/wallet_provider.dart';

const Map<String, Color> _assetTypeColors = {
  'gold': Color(0xFFD97706),
  'real_estate': Color(0xFF059669),
  'stock': Color(0xFF2563EB),
  'crypto': Color(0xFF7C3AED),
  'savings': Color(0xFF0D9488),
  'hui_phuong': Color(0xFFEA580C),
  'simple_asset': AppColors.primary,
};

Color _assetTypeColor(String? key) =>
    _assetTypeColors[key] ?? AppColors.primary;

String _assetTypeEmoji(String? key) {
  switch (key) {
    case 'gold':
      return '🪙';
    case 'real_estate':
      return '🏡';
    case 'stock':
      return '📈';
    case 'crypto':
      return '⚡';
    case 'savings':
      return '🏦';
    case 'hui_phuong':
      return '🤝';
    default:
      return '💎';
  }
}

String _assetTypeLabel(String? key) {
  switch (key) {
    case 'gold':
      return 'Vàng & Kim loại quý';
    case 'real_estate':
      return 'Bất động sản';
    case 'stock':
      return 'Cổ phiếu & Chứng khoán';
    case 'crypto':
      return 'Crypto & Tài sản số';
    case 'savings':
      return 'Sổ tiết kiệm ngân hàng';
    case 'hui_phuong':
      return 'Hụi / Phường';
    default:
      return 'Tài sản đầu tư';
  }
}

class AssetScreen extends StatefulWidget {
  final String userId;
  final bool isTab;
  const AssetScreen({super.key, required this.userId, this.isTab = false});

  @override
  State<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  StreamSubscription<String>? _eventsSub;
  String _selectedSubtype =
      'all'; // 'all', 'gold_re', 'stock_crypto', 'savings', 'hui_phuong'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MoreProvider>();
      provider.load(widget.userId);
      context.read<WalletProvider>().load(widget.userId);
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

  List<Asset> _filterAssets(List<Asset> allAssets) {
    return allAssets.where((a) {
      if (a.status != 'active') return false;

      // Subtype category filter
      final key = a.investmentSubtype ?? a.assetTypeKey ?? 'simple_asset';
      if (_selectedSubtype == 'gold_re' &&
          key != 'gold' &&
          key != 'real_estate') {
        return false;
      }
      if (_selectedSubtype == 'stock_crypto' &&
          key != 'stock' &&
          key != 'crypto') {
        return false;
      }
      if (_selectedSubtype == 'savings' && key != 'savings') {
        return false;
      }
      if (_selectedSubtype == 'hui_phuong' && key != 'hui_phuong') {
        return false;
      }

      return true;
    }).toList();
  }

  void _confirmDelete(Asset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa tài sản'),
        content: Text('Bạn có chắc chắn muốn xóa "${asset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<MoreProvider>().deleteAsset(widget.userId, asset.id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF162032) : Colors.white;
    final borderColor = isDark ? const Color(0xFF24344D) : const Color(0xFFE2E8F0);

    final provider = context.watch<MoreProvider>();
    final activeAssets =
        provider.assets.where((a) => a.status == 'active').toList();
    final displayAssets = _filterAssets(activeAssets);

    final totalCost = activeAssets.fold<int>(0, (s, a) => s + a.costBasis);
    final totalMarket = activeAssets.fold<int>(0, (s, a) => s + a.marketValue);
    final totalProfit = totalMarket - totalCost;
    final profitPct = totalCost > 0 ? (totalProfit / totalCost) * 100.0 : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tài sản & Đầu tư',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Danh mục tích luỹ và đầu tư dài hạn',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (!widget.isTab && Navigator.of(context).canPop())
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 19,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: _openAdd,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero Card: Total Market Value & Performance (Soft Glass)
            FinoraSoftGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TỔNG GIÁ TRỊ TÀI SẢN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: secondaryTextColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${activeAssets.length} tài sản',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatVND(totalMarket),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: primaryTextColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (totalCost > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (totalProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            totalProfit >= 0 ? LucideIcons.trending_up : LucideIcons.trending_down,
                            size: 14,
                            color: totalProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Lợi nhuận: ${totalProfit >= 0 ? '+' : ''}${formatVND(totalProfit)} (${profitPct.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: totalProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter Tabs (Horizontal scrolling pills)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildSubtypeFilterPill('all', 'Tất cả (${activeAssets.length})', isDark),
                  _buildSubtypeFilterPill('gold_re', 'Vàng & BĐS', isDark),
                  _buildSubtypeFilterPill('stock_crypto', 'Cổ phiếu & Crypto', isDark),
                  _buildSubtypeFilterPill('savings', 'Sổ tiết kiệm', isDark),
                  _buildSubtypeFilterPill('hui_phuong', 'Hụi / Phường', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List of Assets or Empty State
            if (displayAssets.isEmpty) ...[
              FinoraSoftGlassCard(
                radius: 20,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF24344D) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.landmark,
                        size: 28,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      activeAssets.isEmpty
                          ? 'Chưa có tài sản tích luỹ nào'
                          : 'Không có tài sản trong mục này',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thêm vàng, sổ tiết kiệm, bất động sản, chứng khoán hoặc dây hụi để quản lý tập trung.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _openAdd,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Thêm tài sản',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...displayAssets.map(
                (asset) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AssetCard(
                    asset: asset,
                    onEdit: () => _openEdit(asset),
                    onDelete: () => _confirmDelete(asset),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubtypeFilterPill(String key, String label, bool isDark) {
    final isSelected = _selectedSubtype == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedSubtype = key);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A))
              : (isDark ? const Color(0xFF162032) : Colors.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF24344D) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A))
                        .withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssetCard({
    required this.asset,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final subtype =
        asset.investmentSubtype ?? asset.assetTypeKey ?? 'simple_asset';
    final tint = _assetTypeColor(subtype);
    final profit = asset.marketValue - asset.costBasis;
    final profitPct =
        asset.costBasis > 0 ? (profit / asset.costBasis) * 100.0 : 0.0;
    final profitColor = profit >= 0 ? AppColors.success : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF161B26).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E293B))
                .withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Name + Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: isDark ? 0.20 : 0.12),
                  border: Border.all(
                    color: tint.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _assetTypeEmoji(subtype),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _assetTypeLabel(subtype),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: tint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatVND(asset.marketValue),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${profit >= 0 ? '+' : ''}${formatVND(profit)} (${profitPct.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: profitColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Subtype-specific metrics
          if (subtype == 'hui_phuong') ...[
            _buildHuiMetrics(
                asset, isDark, primaryTextColor, secondaryTextColor),
          ] else if (subtype == 'savings') ...[
            _buildSavingsMetrics(
                asset, isDark, primaryTextColor, secondaryTextColor),
          ] else ...[
            _buildStandardMetrics(
                asset, isDark, primaryTextColor, secondaryTextColor),
          ],

          const SizedBox(height: 8),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Cập nhật',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.35)),
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 14, color: AppColors.error),
                label: const Text('Xóa',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.35)),
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHuiMetrics(
      Asset a, bool isDark, Color textPrimary, Color textSecondary) {
    final progress = a.totalPeriods > 0
        ? (a.currentPeriod / a.totalPeriods).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiến độ kỳ: ${a.currentPeriod}/${a.totalPeriods}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              'Mỗi kỳ: ${formatVND(a.periodAmount)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đã đóng: ${formatVND(a.contributedAmount)}',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
            Text(
              'Đã lĩnh: ${formatVND(a.receivedAmount)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavingsMetrics(
      Asset a, bool isDark, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lãi suất / năm',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              '${a.interestRate.toStringAsFixed(1)}% / năm',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D9488),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Kỳ hạn gửi',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              '${a.termMonths} tháng',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Tiền gửi gốc',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              formatVND(a.costBasis),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStandardMetrics(
      Asset a, bool isDark, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Số lượng: ${a.quantity} ${a.unit ?? ''}',
          style: TextStyle(
              fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
        ),
        Text(
          'Giá vốn: ${formatVND(a.buyPrice)}',
          style: TextStyle(
              fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
        ),
        Text(
          'Giá TT: ${formatVND(a.currentPrice)}',
          style: TextStyle(
              fontSize: 12, color: textPrimary, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

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
  final _periodAmountController = TextEditingController(text: '2000000');
  final _totalPeriodsController = TextEditingController(text: '12');
  final _currentPeriodController = TextEditingController(text: '1');
  final _contributedAmountController = TextEditingController(text: '2000000');
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
      _buyPriceController.text = a.buyPrice > 0 ? a.buyPrice.toString() : '';
      _currentPriceController.text =
          a.currentPrice > 0 ? a.currentPrice.toString() : '';

      _interestRateController.text = a.interestRate.toString();
      _termMonthsController.text = a.termMonths.toString();

      _periodAmountController.text = a.periodAmount.toString();
      _totalPeriodsController.text = a.totalPeriods.toString();
      _currentPeriodController.text = a.currentPeriod.toString();
      _contributedAmountController.text = a.contributedAmount.toString();
      _receivedAmountController.text = a.receivedAmount.toString();
    } else {
      _applySubtypeDefaults(_subtype);
    }
  }

  void _applySubtypeDefaults(String type) {
    switch (type) {
      case 'gold':
        _unitController.text = 'chỉ';
        if (_nameController.text.isEmpty)
          _nameController.text = 'Vàng SJC 9999';
        break;
      case 'real_estate':
        _unitController.text = 'm2';
        if (_nameController.text.isEmpty)
          _nameController.text = 'Bất động sản đất nền';
        break;
      case 'stock':
        _unitController.text = 'cổ phiếu';
        if (_nameController.text.isEmpty) _nameController.text = 'Cổ phiếu FPT';
        break;
      case 'crypto':
        _unitController.text = 'coin';
        if (_nameController.text.isEmpty)
          _nameController.text = 'Bitcoin (BTC)';
        break;
      case 'savings':
        _unitController.text = 'sổ';
        if (_nameController.text.isEmpty)
          _nameController.text = 'Tiết kiệm Vietcombank';
        break;
      case 'hui_phuong':
        _unitController.text = 'dây';
        if (_nameController.text.isEmpty)
          _nameController.text = 'Dây Hụi 2 Triệu/Tháng';
        break;
      default:
        _unitController.text = 'món';
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _typeRadio('gold', '🪙 Vàng', isDark),
                  _typeRadio('real_estate', '🏡 BĐS', isDark),
                  _typeRadio('stock', '📈 Cổ phiếu', isDark),
                  _typeRadio('crypto', '⚡ Crypto', isDark),
                  _typeRadio('savings', '🏦 Sổ tiết kiệm', isDark),
                  _typeRadio('hui_phuong', '🤝 Hụi/Phường', isDark),
                  _typeRadio('simple_asset', '💎 Khác', isDark),
                ],
              ),
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
                    _buildInput(_periodAmountController, '2000000', isDark,
                        isNumber: true),
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
                                  isNumber: true),
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
                                  isNumber: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else if (_subtype == 'savings') ...[
                    _fieldLabel('Số tiền gửi gốc (VND)', primaryTextColor),
                    _buildInput(_buyPriceController, '100000000', isDark,
                        isNumber: true),
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
                                  _unitController, 'chỉ, m2, cp...', isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel(
                        'Giá mua vào / Giá vốn đơn vị (VND)', primaryTextColor),
                    _buildInput(_buyPriceController, 'Giá lúc mua', isDark,
                        isNumber: true),
                    const SizedBox(height: 14),
                    _fieldLabel('Giá thị trường hiện tại đơn vị (VND)',
                        primaryTextColor),
                    _buildInput(_currentPriceController, 'Giá hôm nay', isDark,
                        isNumber: true),
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

  Widget _typeRadio(String key, String label, bool isDark) {
    final isSelected = _subtype == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: LiquidFilterPill(
        label: label,
        selected: isSelected,
        color: _assetTypeColor(key),
        onTap: () {
          setState(() {
            _subtype = key;
            _applySubtypeDefaults(key);
          });
        },
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
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
