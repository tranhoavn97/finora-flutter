import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../catalog_mock_data.dart';
import '../widgets/catalog_bottom_sheets.dart';
import '../widgets/catalog_glass_card.dart';

final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

/// Screen 1: Dashboard (Tổng quan tài chính & số dư) in Glassmorphism 2.0
class DemoDashboardScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;
  const DemoDashboardScreen({super.key, this.isLiveMode = false, this.onBack});

  @override
  State<DemoDashboardScreen> createState() => _DemoDashboardScreenState();
}

class _DemoDashboardScreenState extends State<DemoDashboardScreen> {
  int _selectedDateFilterIndex = 0;
  final List<String> _dateFilters = ['Tháng này', 'Hôm nay', 'Tuần này', 'Năm nay'];
  int _selectedWealthTabIndex = 0;
  final List<String> _wealthTabs = ['Ví & Thẻ', 'Đầu tư', 'Cho vay'];
  final TextEditingController _quickLogController = TextEditingController();

  List<CatalogTransactionItem> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _recentTransactions = List.from(CatalogMockData.transactions);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AmbientFloatingBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 136),
        children: [
          // 1. Unified Majestic Glass Cockpit (Header + Date Tabs + Balance + Metrics + Pill Actions)
          _buildUnifiedHeroCockpit(isDark),
          const SizedBox(height: 14),

          // 2. AI Quick Log Capsule Bar
          _buildAiQuickLogBar(isDark),
          const SizedBox(height: 14),

          // 3. AI Financial Health Score Card
          _buildHealthScoreCard(isDark),
          const SizedBox(height: 14),

          // 4. Wealth Tabs Section (Seamless Contiguous Segmented Pill Dock)
          _buildWealthSection(isDark),
          const SizedBox(height: 14),

          // 5. Recent Transactions Section
          _buildRecentTransactionsSection(isDark),
        ],
      ),
    );
  }

  Widget _buildUnifiedHeroCockpit(bool isDark) {
    return CatalogGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: User Avatar, Name, and Notification Bell Pill
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
                    child: const Text(
                      'HT',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào, Hòa Trần (Louis)',
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
              // Bell Notification Pill
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

          // Date Filter: Seamless Contiguous Segmented Pill Tabs
          FinoraSegmentedTabs(
            labels: _dateFilters,
            selectedIndex: _selectedDateFilterIndex,
            onChanged: (index) => setState(() => _selectedDateFilterIndex = index),
            compact: true,
            height: 36,
          ),
          const SizedBox(height: 16),

          // Net Worth Headline & Trend Pill Badge
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
                    '${_vnd.format(CatalogMockData.totalNetWorth)} đ',
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
                  borderRadius: BorderRadius.circular(999), // True pill
                  color: GlassmorphismTokens.income.withValues(alpha: 0.16),
                  border: Border.all(color: GlassmorphismTokens.income.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.trending_up, size: 12, color: GlassmorphismTokens.income),
                    SizedBox(width: 4),
                    Text(
                      '+12.4% / tháng',
                      style: TextStyle(color: GlassmorphismTokens.income, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Seamless Metrics Trio with Hairline Dividers
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
                    '+${_vnd.format(CatalogMockData.periodIncome)}đ',
                    GlassmorphismTokens.income,
                  ),
                ),
                Container(width: 1, height: 28, color: isDark ? Colors.white12 : Colors.black12),
                Expanded(
                  child: _buildCockpitMetric(
                    'Chi ra',
                    '-${_vnd.format(CatalogMockData.periodExpense)}đ',
                    GlassmorphismTokens.expense,
                  ),
                ),
                Container(width: 1, height: 28, color: isDark ? Colors.white12 : Colors.black12),
                Expanded(
                  child: _buildCockpitMetric(
                    'Dòng tiền',
                    '+${_vnd.format(CatalogMockData.periodNet)}đ',
                    const Color(0xFF5AC8FA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Quick Action Buttons - True Pill Capsules
          _buildQuickActions(isDark),
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

  Widget _buildQuickActions(bool isDark) {
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
                  showCatalogAddEntityModal(
                    context: context,
                    entityName: 'Giao dịch',
                    onCreated: (name) {
                      setState(() {
                        _recentTransactions.insert(
                          0,
                          CatalogTransactionItem(
                            id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                            title: name,
                            category: 'Khác',
                            amount: 85000,
                            isExpense: true,
                            walletName: 'Vietcombank',
                            memberTag: '👨 Chồng',
                            date: 'Hôm nay',
                            time: 'Vừa xong',
                            icon: LucideIcons.shopping_bag,
                            categoryColor: GlassmorphismTokens.primary,
                            note: 'Thêm nhanh từ Dashboard',
                          ),
                        );
                      });
                    },
                  );
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
                  borderRadius: BorderRadius.circular(999), // True pill capsule
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

  Widget _buildAiQuickLogBar(bool isDark) {
    return CatalogGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      radius: 999, // True pill capsule
      child: Row(
        children: [
          const Icon(LucideIcons.sparkles, color: GlassmorphismTokens.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _quickLogController,
              decoration: const InputDecoration(
                hintText: 'Nhập nhanh với AI: "Ăn trưa 45k", "Đổ xăng 70k"...',
                hintStyle: TextStyle(fontSize: 12.5),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _recentTransactions.insert(
                      0,
                      CatalogTransactionItem(
                        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                        title: text.trim(),
                        category: 'Ăn uống',
                        amount: 45000,
                        isExpense: true,
                        walletName: 'Vietcombank',
                        memberTag: '👨 Chồng',
                        date: 'Hôm nay',
                        time: 'Vừa xong',
                        icon: LucideIcons.utensils,
                        categoryColor: const Color(0xFFFF9500),
                        note: 'Ghi chép tự nhiên bằng AI NLP',
                      ),
                    );
                    _quickLogController.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Finora NLP đã tự động phân loại & lưu giao dịch!'),
                      backgroundColor: GlassmorphismTokens.income,
                    ),
                  );
                }
              },
            ),
          ),
          // Pill Action Button for Voice/Quick Log
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _quickLogController.text = 'Đổ xăng 70k MoMo';
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: GlassmorphismTokens.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999), // True pill
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

  Widget _buildHealthScoreCard(bool isDark) {
    return CatalogGlassCard(
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
                child: const Text('86/100 • Rất tốt',
                    style: TextStyle(color: GlassmorphismTokens.income, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _healthMetricItem('Quỹ khẩn cấp', '${CatalogMockData.emergencyFundMonths} tháng', GlassmorphismTokens.income),
              ),
              Expanded(
                child: _healthMetricItem('Tỷ lệ tích lũy', '${(CatalogMockData.savingRatio * 100).toInt()}%', GlassmorphismTokens.primary),
              ),
              Expanded(
                child: _healthMetricItem('Tỷ lệ nợ', '${(CatalogMockData.debtRatio * 100).toInt()}%', const Color(0xFF5AC8FA)),
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

  Widget _buildWealthSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinoraSegmentedTabs(
          labels: _wealthTabs,
          selectedIndex: _selectedWealthTabIndex,
          onChanged: (index) => setState(() => _selectedWealthTabIndex = index),
          height: 38,
        ),
        const SizedBox(height: 12),
        if (_selectedWealthTabIndex == 0)
          ...CatalogMockData.wallets.take(3).map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CatalogGlassCard(
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
                              color: w.color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(LucideIcons.credit_card, color: w.color, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text(w.accountNumber, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
        else if (_selectedWealthTabIndex == 1)
          ...CatalogMockData.assets.take(3).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CatalogGlassCard(
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
                              color: a.color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(a.icon, color: a.color, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text('${a.quantity} ${a.unit}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${_vnd.format(a.marketValue)} ₫',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ))
        else
          ...CatalogMockData.loans.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CatalogGlassCard(
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
                              color: l.color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(l.isLending ? LucideIcons.hand_coins : LucideIcons.receipt, color: l.color, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text('Hạn: ${l.dueDate}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${_vnd.format(l.remainingAmount)} ₫',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: l.color),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Giao dịch gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chuyển đến màn hình Lịch sử giao dịch đầy đủ')),
                );
              },
              child: const Text('Xem tất cả', style: TextStyle(color: GlassmorphismTokens.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ..._recentTransactions.take(5).map((tx) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CatalogGlassCard(
              onTap: () {
                showCatalogTransactionDetailSheet(
                  context: context,
                  transaction: tx,
                  onDelete: () {
                    setState(() {
                      _recentTransactions.removeWhere((item) => item.id == tx.id);
                    });
                  },
                );
              },
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tx.categoryColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tx.icon, color: tx.categoryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(tx.walletName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const Text(' • ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(tx.memberTag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${tx.isExpense ? '-' : '+'}${_vnd.format(tx.amount)} ₫',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: tx.isExpense ? GlassmorphismTokens.expense : GlassmorphismTokens.income,
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
