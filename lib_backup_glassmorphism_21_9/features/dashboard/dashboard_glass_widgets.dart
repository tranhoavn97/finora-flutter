import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../core/design_system/v8/finora_v8_controls.dart';
import '../../core/design_system/glassmorphism_tokens.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../state/dashboard_provider.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';

final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

class DashboardUnifiedHeroCockpit extends StatelessWidget {
  final DashboardData d;
  final bool isDark;
  final String userName;
  final VoidCallback onAddTransaction;
  final Function(int) onDateFilterChanged;

  const DashboardUnifiedHeroCockpit({
    super.key,
    required this.d,
    required this.isDark,
    required this.userName,
    required this.onAddTransaction,
    required this.onDateFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào, $userName',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Icon(LucideIcons.sparkles, size: 12, color: GlassmorphismTokens.primary),
                          SizedBox(width: 4),
                          Text(
                            'Tài chính thông minh Finora AI',
                            style: TextStyle(fontSize: 11, color: GlassmorphismTokens.neutral, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      LucideIcons.bell,
                      size: 18,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: GlassmorphismTokens.expense,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FinoraSegmentedTabs(
            labels: const ['Hôm nay', 'Tuần này', 'Tháng này', 'Năm nay', 'Tùy chọn'],
            selectedIndex: d.selectedDateFilter.index,
            onChanged: onDateFilterChanged,
            compact: true,
            height: 36,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TỔNG TÀI SẢN RÒNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: GlassmorphismTokens.neutral,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_vnd.format(d.totalWalletBalance + d.totalAssetsValue - d.totalCreditCardDebt)} đ',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: GlassmorphismTokens.income.withValues(alpha: 0.16),
                  border: Border.all(color: GlassmorphismTokens.income.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.trending_up, size: 12, color: GlassmorphismTokens.income),
                    SizedBox(width: 4),
                    Text(
                      '+0.0% / tháng',
                      style: TextStyle(color: GlassmorphismTokens.income, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCockpitMetric(
                    'Thu vào',
                    '+${_vnd.format(d.periodIncome)}đ',
                    GlassmorphismTokens.income,
                  ),
                ),
                Container(width: 1, height: 28, color: isDark ? Colors.white12 : Colors.black12),
                Expanded(
                  child: _buildCockpitMetric(
                    'Chi ra',
                    '-${_vnd.format(d.periodExpense)}đ',
                    GlassmorphismTokens.expense,
                  ),
                ),
                Container(width: 1, height: 28, color: isDark ? Colors.white12 : Colors.black12),
                Expanded(
                  child: _buildCockpitMetric(
                    'Dòng tiền',
                    '${d.periodNet >= 0 ? '+' : ''}${_vnd.format(d.periodNet)}đ',
                    const Color(0xFF5AC8FA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildCockpitMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: GlassmorphismTokens.neutral, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'label': 'Ghi chép', 'icon': LucideIcons.plus, 'color': GlassmorphismTokens.primary},
      {'label': 'Ví & thẻ', 'icon': LucideIcons.wallet, 'color': const Color(0xFF5856D6)},
      {'label': 'Báo cáo', 'icon': LucideIcons.chart_pie, 'color': const Color(0xFF34C759)},
      {'label': 'AI Finora', 'icon': LucideIcons.sparkles, 'color': const Color(0xFFFF9500)},
    ];

    return Row(
      children: actions.map((act) {
        final color = act['color'] as Color;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (act['label'] == 'Ghi chép') {
                  onAddTransaction();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mở chức năng ${act['label']}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.38),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(act['icon'] as IconData, color: color, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        act['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DashboardAiQuickLogBar extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback onVoiceTap;

  const DashboardAiQuickLogBar({
    super.key,
    required this.isDark,
    required this.controller,
    required this.onSubmitted,
    required this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      radius: 999, // True pill capsule
      child: Row(
        children: [
          const Icon(LucideIcons.sparkles, color: GlassmorphismTokens.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Nhập nhanh với AI: "Ăn trưa 45k", "Đổ xăng 70k"...',
                hintStyle: TextStyle(fontSize: 12.5),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
          GestureDetector(
            onTap: onVoiceTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: GlassmorphismTokens.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: GlassmorphismTokens.primary.withValues(alpha: 0.35)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.mic, color: GlassmorphismTokens.primary, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Ghi nhanh',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GlassmorphismTokens.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardHealthScoreCard extends StatelessWidget {
  final DashboardData d;
  final bool isDark;

  const DashboardHealthScoreCard({
    super.key,
    required this.d,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.heart_pulse, color: GlassmorphismTokens.income, size: 20),
                  SizedBox(width: 8),
                  Text('Sức khỏe tài chính AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: GlassmorphismTokens.income.withValues(alpha: 0.16),
                  border: Border.all(color: GlassmorphismTokens.income.withValues(alpha: 0.4)),
                ),
                child: Text('${d.aiHealthScore.toInt()}/100 • Khá tốt',
                    style: const TextStyle(color: GlassmorphismTokens.income, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _healthMetricItem('Quỹ khẩn cấp', '${d.emergencyRunwayMonths.toStringAsFixed(1)} tháng', GlassmorphismTokens.income),
              ),
              Expanded(
                child: _healthMetricItem('Tỷ lệ tích lũy', '${d.savingsRatePercent.toInt()}%', GlassmorphismTokens.primary),
              ),
              Expanded(
                child: _healthMetricItem('Tỷ lệ nợ', '${d.debtRatioPercent.toInt()}%', const Color(0xFF5AC8FA)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: GlassmorphismTokens.neutral)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class DashboardWealthSection extends StatelessWidget {
  final DashboardData d;
  final bool isDark;
  final int selectedIndex;
  final Function(int) onChanged;

  const DashboardWealthSection({
    super.key,
    required this.d,
    required this.isDark,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasLoansAndAssets = false; // Mock - we will only show wallets for now or placeholder
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinoraSegmentedTabs(
          labels: const ['Ví & thẻ', 'Tài sản', 'Nợ & Cho vay'],
          selectedIndex: selectedIndex,
          onChanged: onChanged,
          height: 38,
        ),
        const SizedBox(height: 12),
        if (selectedIndex == 0)
          ...d.wallets.take(3).map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5856D6).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.credit_card, color: Color(0xFF5856D6), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text(w.type.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${_vnd.format(w.balance)} ₫',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: w.balance >= 0 ? (isDark ? Colors.white : const Color(0xFF0F172A)) : GlassmorphismTokens.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
        else
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Center(
               child: Text('Tính năng đang phát triển', style: TextStyle(color: GlassmorphismTokens.neutral)),
             ),
           )
      ],
    );
  }
}

class DashboardRecentTransactionsSection extends StatelessWidget {
  final List<TransactionModel> txList;
  final bool isDark;
  final VoidCallback onViewAll;

  const DashboardRecentTransactionsSection({
    super.key,
    required this.txList,
    required this.isDark,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Giao dịch gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: onViewAll,
              child: const Text('Xem tất cả', style: TextStyle(color: GlassmorphismTokens.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...txList.take(5).map((tx) {
          final isExpense = tx.type == 'expense';
          final color = isExpense ? GlassmorphismTokens.expense : GlassmorphismTokens.income;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingGlassCard(
              onTap: () {}, // Can be wired up later to open tx detail
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense ? LucideIcons.arrow_down_right : LucideIcons.arrow_up_right,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.note?.isNotEmpty == true ? tx.note! : (tx.categoryName ?? 'Khác'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              tx.categoryName ?? 'Khác',
                              style: const TextStyle(fontSize: 11.5, color: GlassmorphismTokens.neutral),
                            ),
                            const Text(' • ', style: TextStyle(fontSize: 11.5, color: GlassmorphismTokens.neutral)),
                            Text(
                              DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(tx.date)),
                              style: const TextStyle(fontSize: 11.5, color: GlassmorphismTokens.neutral),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isExpense ? '-' : '+'}${_vnd.format(tx.amount)} ₫',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
