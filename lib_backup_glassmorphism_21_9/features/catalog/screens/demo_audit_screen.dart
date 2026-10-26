import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../catalog_mock_data.dart';
import '../widgets/catalog_glass_card.dart';

/// Screen 12: Audit (Nhật ký kiểm toán & lịch sử thay đổi) in Glassmorphism 2.0
class DemoAuditScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoAuditScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoAuditScreen> createState() => _DemoAuditScreenState();
}

class _DemoAuditScreenState extends State<DemoAuditScreen> {
  String _selectedAction = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allLogs = CatalogMockData.auditLogs;
    final logs = allLogs.where((l) {
      if (_selectedAction == 'Tất cả') return true;
      if (_selectedAction == 'Cập nhật') return l.type == AuditType.update;
      if (_selectedAction == 'Thêm mới') return l.type == AuditType.create;
      if (_selectedAction == 'Khôi phục') return l.type == AuditType.restore;
      return true;
    }).toList();

    final filters = ['Tất cả', 'Thêm mới', 'Cập nhật', 'Khôi phục'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FinoraPageHeader(
                  title: 'Nhật ký kiểm toán',
                  onBack: widget.onBack ?? () => Navigator.maybePop(context),
                  actions: [
                    FinoraHeaderIconButton(
                      icon: LucideIcons.shield_check,
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: CatalogGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GlassmorphismTokens.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.shield_check, color: GlassmorphismTokens.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toàn vẹn dữ liệu tài chính',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Mọi thay đổi số dư, giao dịch, ví và ngân sách đều được ghi nhật ký bất biến.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: filters.map((f) {
                      final isSel = _selectedAction == f;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedAction = f);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? GlassmorphismTokens.primary.withValues(alpha: isDark ? 0.35 : 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel
                                  ? GlassmorphismTokens.primary.withValues(alpha: 0.6)
                                  : (isDark ? Colors.white12 : Colors.black12),
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                              color: isSel ? GlassmorphismTokens.primary : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final log = logs[idx];
                    return _buildLogCard(log, isDark);
                  },
                  childCount: logs.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(CatalogAuditItem log, bool isDark) {
    Color badgeColor;
    IconData icon;

    switch (log.type) {
      case AuditType.create:
        badgeColor = GlassmorphismTokens.income;
        icon = LucideIcons.plus;
        break;
      case AuditType.update:
        badgeColor = GlassmorphismTokens.primary;
        icon = LucideIcons.file_pen;
        break;
      case AuditType.restore:
        badgeColor = const Color(0xFFAF52DE);
        icon = LucideIcons.rotate_ccw;
        break;
      case AuditType.delete:
        badgeColor = GlassmorphismTokens.expense;
        icon = LucideIcons.trash;
        break;
      case AuditType.info:
        badgeColor = GlassmorphismTokens.warning;
        icon = LucideIcons.info;
        break;
    }

    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: badgeColor, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    log.action,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.collection,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ],
              ),
              Text(
                log.time,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            log.details,
            style: const TextStyle(fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.user, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Thực hiện bởi: ${log.actor}',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
