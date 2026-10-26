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

/// Screen 2: Transaction (Lịch sử & chi tiết giao dịch) in Glassmorphism 2.0
class DemoTransactionScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;
  const DemoTransactionScreen({super.key, this.isLiveMode = false, this.onBack});

  @override
  State<DemoTransactionScreen> createState() => _DemoTransactionScreenState();
}

class _DemoTransactionScreenState extends State<DemoTransactionScreen> {
  late List<CatalogTransactionItem> _allTransactions;
  String _selectedType = 'Tất cả';
  String _selectedMember = 'Tất cả';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _types = ['Tất cả', 'Chi', 'Thu', 'Chuyển'];
  final List<String> _members = ['Tất cả', '👨 Chồng', '👩 Vợ', '👨👩👧 Chung'];

  @override
  void initState() {
    super.initState();
    _allTransactions = List.from(CatalogMockData.transactions);
  }

  List<CatalogTransactionItem> get _filteredTransactions {
    return _allTransactions.where((tx) {
      if (_selectedType == 'Chi' && !tx.isExpense) return false;
      if (_selectedType == 'Thu' && tx.isExpense) return false;
      if (_selectedType == 'Chuyển' && !tx.isTransfer) return false;
      if (_selectedMember != 'Tất cả' && tx.memberTag != _selectedMember) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = tx.title.toLowerCase().contains(query);
        final matchCat = tx.category.toLowerCase().contains(query);
        final matchWallet = tx.walletName.toLowerCase().contains(query);
        if (!matchTitle && !matchCat && !matchWallet) return false;
      }
      return true;
    }).toList();
  }

  int get _totalExpense {
    return _filteredTransactions
        .where((tx) => tx.isExpense && !tx.isTransfer)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  int get _totalIncome {
    return _filteredTransactions
        .where((tx) => !tx.isExpense)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = _filteredTransactions;

    return AmbientFloatingBackground(
      child: Column(
        children: [
          // 1. Apple HIG Header
          FinoraPageHeader(
            title: 'Lịch sử giao dịch',
            actions: [
              FinoraAddIconButton(
                onTap: () {
                  showCatalogAddEntityModal(
                    context: context,
                    entityName: 'Giao dịch mới',
                    onCreated: (name) {
                      setState(() {
                        _allTransactions.insert(
                          0,
                          CatalogTransactionItem(
                            id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                            title: name,
                            category: 'Mua sắm',
                            amount: 150000,
                            isExpense: true,
                            walletName: 'Vietcombank',
                            memberTag: _selectedMember == 'Tất cả' ? '👨 Chồng' : _selectedMember,
                            date: '21/09/2026',
                            time: '12:00',
                            icon: LucideIcons.shopping_bag,
                            categoryColor: const Color(0xFFAF52DE),
                            note: 'Giao dịch ghi chép tức thời',
                          ),
                        );
                      });
                    },
                  );
                },
              ),
            ],
          ),

          // 2. Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 136),
              children: [
                // Compact Spending Hero Card
                CatalogGlassCard(
                  padding: const EdgeInsets.all(16),
                  customFill: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.85),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Tổng chi', style: TextStyle(fontSize: 12, color: GlassmorphismTokens.neutral)),
                          const SizedBox(height: 4),
                          Text(
                            '-${_vnd.format(_totalExpense)} ₫',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: GlassmorphismTokens.expense,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 28, width: 0.5, color: Colors.grey.withValues(alpha: 0.3)),
                      Column(
                        children: [
                          const Text('Tổng thu', style: TextStyle(fontSize: 12, color: GlassmorphismTokens.neutral)),
                          const SizedBox(height: 4),
                          Text(
                            '+${_vnd.format(_totalIncome)} ₫',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: GlassmorphismTokens.income,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 28, width: 0.5, color: Colors.grey.withValues(alpha: 0.3)),
                      Column(
                        children: [
                          const Text('Số lượng', style: TextStyle(fontSize: 12, color: GlassmorphismTokens.neutral)),
                          const SizedBox(height: 4),
                          Text(
                            '${transactions.length} GD',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Search Bar
                CatalogGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  radius: 20,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên, danh mục, ví...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Pill Rows: Type Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _types.map((type) {
                      final selected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FinoraFilterPill(
                          label: type,
                          selected: selected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedType = type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Member Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _members.map((member) {
                      final selected = _selectedMember == member;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FinoraFilterPill(
                          label: member,
                          selected: selected,
                          color: const Color(0xFF5856D6),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedMember = member);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Transactions List
                if (transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(LucideIcons.inbox, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Không tìm thấy giao dịch phù hợp', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                else
                  ...transactions.map((tx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CatalogGlassCard(
                        onTap: () {
                          showCatalogTransactionDetailSheet(
                            context: context,
                            transaction: tx,
                            onDelete: () {
                              setState(() {
                                _allTransactions.removeWhere((item) => item.id == tx.id);
                              });
                            },
                          );
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: tx.categoryColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(tx.icon, color: tx.categoryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(tx.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      const Text(' • ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(tx.walletName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      const Text(' • ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: Colors.blue.withValues(alpha: 0.12),
                                        ),
                                        child: Text(
                                          tx.memberTag,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
                                        ),
                                      ),
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
            ),
          ),
        ],
      ),
    );
  }
}
